using Toybox.Application as App;
using Toybox.Communications as Comm;
using Toybox.Lang as Lang;
using Toybox.System as Sys;

// Storage-backed queue + hand-rolled JSON (CIQ has no JSON writer).
// Client-generated keys make PUT /api/v2/records idempotent.
// Persistence: one small Storage key per record ("q<i>" = "key,t1,t2,ds,mt,st")
// — a single big value trips memory/watchdog limits (verified in simulator).
class SyncClient {
    static var QUEUE_CAP = 500;
    hidden var queue;
    hidden var inFlight = false;
    // Snapshot at initialize(): Properties are per-app-instance settings that
    // tests must be able to detach from (setEndpoint("", "")) before flushing.
    hidden var url = "";
    hidden var token = "";

    function initialize() {
        queue = [];
        url = App.Properties.getValue("ttUrl");
        token = App.Properties.getValue("ttToken");
        if (url == null) {
            url = "";
        }
        if (token == null) {
            token = "";
        }
        var size = App.Storage.getValue("qsize");
        if (size != null) {
            for (var i = 0; i < size; i++) {
                var s = App.Storage.getValue(keyAt(i));
                if (s != null) {
                    queue.add(parseRecord(s));
                }
            }
        }
    }

    function queuedCount() {
        return queue.size();
    }

    function record(i) {
        return queue[i];
    }

    function enqueue(record) {
        var overflow = queue.size() >= QUEUE_CAP;
        if (overflow) {
            // Array.remove is unreliable for index drops — rebuild without the oldest
            var kept = [];
            for (var i = 1; i < queue.size(); i++) {
                kept.add(queue[i]);
            }
            queue = kept;
            // shortcut: minutes-level loss possible past 500 records, upgrade to flash-based file if ever hit
            Sys.println("SyncClient: queue overflow, dropped oldest record");
        }
        queue.add(record);
        if (overflow) {
            writeAll(); // indices shifted — rewrite
        } else {
            App.Storage.setValue(keyAt(queue.size() - 1), serializeRecord(record));
            App.Storage.setValue("qsize", queue.size());
        }
        flush();
    }

    function setEndpoint(u as Lang.String, t as Lang.String) {
        url = u;
        token = t;
    }

    function flush() {
        if (inFlight || queue.size() == 0) {
            return;
        }
        var app = App.getApp();
        if (app == null) {
            return; // unit-test context: no app, no network
        }
        if (url.equals("") || token.equals("")) {
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
    function recordJson(r) {
        return Lang.format("{\"key\":\"$1$\",\"t1\":$2$,\"t2\":$3$,\"ds\":\"$4$\",\"mt\":$5$,\"st\":0}",
            [r.get("key"), r.get("t1"), r.get("t2"), r.get("ds"), r.get("mt")]);
    }

    hidden function onResponse(code as Lang.Number, data as Lang.Dictionary or Lang.String or Null) as Void {
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
        writeAll();
    }

    hidden function keyAt(i) {
        return "q" + i.toString();
    }

    // "key,t1,t2,ds,mt,st" — ds is comma-free (tags validated [a-z0-9-]+)
    hidden function serializeRecord(r) {
        return r.get("key") + "," + r.get("t1").toString() + ","
               + r.get("t2").toString() + "," + r.get("ds") + ","
               + r.get("mt").toString() + "," + r.get("st").toString();
    }

    hidden function parseRecord(s) {
        var p = ProjectPicker.splitOn(s, ",");
        return {"key" => p[0], "t1" => p[1].toNumber(), "t2" => p[2].toNumber(),
                "ds" => p[3], "mt" => p[4].toNumber(), "st" => p[5].toNumber()};
    }

    hidden function writeAll() {
        for (var i = 0; i < queue.size(); i++) {
            App.Storage.setValue(keyAt(i), serializeRecord(queue[i]));
        }
        App.Storage.setValue("qsize", queue.size());
    }
}
