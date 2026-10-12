using Toybox.Application as App;
using Toybox.Communications as Comm;
using Toybox.Lang as Lang;
using Toybox.System as Sys;

// Storage-backed queue + hand-rolled JSON (CIQ has no JSON writer).
// Client-generated keys make PUT /api/v2/records idempotent.
class SyncClient {
    hidden var queue;
    hidden var inFlight = false;

    function initialize() {
        queue = App.Storage.getValue("syncQueue");
        if (queue == null) {
            queue = [];
        }
    }

    function queuedCount() {
        return queue.size();
    }

    function enqueue(record) {
        queue.add(record);
        if (queue.size() > 500) {
            queue.shift();
            // shortcut: minutes-level loss possible past 500 records, upgrade to flash-based file if ever hit
            Sys.println("SyncClient: queue overflow, dropped oldest record");
        }
        persist();
        flush();
    }

    function flush() {
        if (inFlight || queue.size() == 0) {
            return;
        }
        var app = App.getApp() as PomodoroApp;
        var url = app.setting("ttUrl");
        var token = app.setting("ttToken");
        if (url == null || token == null || url.equals("") || token.equals("")) {
            return;
        }
        if (url.substring(url.length() - 1, url.length()).equals("/")) {
            url = url.substring(0, url.length() - 1);
        }
        var body = "[";
        for (var i = 0; i < queue.size(); i++) {
            if (i > 0) {
                body += ",";
            }
            body += recordJson(queue[i]);
        }
        body += "]";
        inFlight = true;
        Comm.makeWebRequest(url + "/api/v2/records", body,
            {:method => Comm.HTTP_REQUEST_METHOD_PUT,
             :headers => {"authtoken" => token, "Content-Type" => "application/json"},
             :responseType => Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON},
            method(:onResponse));
    }

    // Tag charset [a-z0-9-]+ validated at settings parse — no escaping needed here.
    hidden function recordJson(r) {
        return Lang.format("{\"key\":\"$1$\",\"t1\":$2$,\"t2\":$3$,\"ds\":\"$4$\",\"mt\":$5$,\"st\":0}",
            [r.get("key"), r.get("t1"), r.get("t2"), r.get("ds"), r.get("mt")]);
    }

    hidden function onResponse(code, data) {
        inFlight = false;
        if (code != 200 || data == null || !(data instanceof Lang.Dictionary)) {
            return; // network failure: everything stays queued, retried at next flush trigger
        }
        var done = {};
        var accepted = data.get("accepted");
        if (accepted instanceof Lang.Array) {
            for (var i = 0; i < accepted.size(); i++) {
                done.put(accepted[i].toString(), true);
            }
        }
        var failed = data.get("failed");
        if (failed instanceof Lang.Array) {
            for (var j = 0; j < failed.size(); j++) {
                done.put(failed[j].toString(), true); // permanently rejected: drop, don't poison the queue
            }
        }
        var kept = [];
        for (var k = 0; k < queue.size(); k++) {
            if (done.get(queue[k].get("key").toString()) == null) {
                kept.add(queue[k]);
            }
        }
        queue = kept;
        persist();
    }

    hidden function persist() {
        if (queue.size() == 0) {
            App.Storage.deleteValue("syncQueue");
        } else {
            App.Storage.setValue("syncQueue", queue);
        }
    }
}
