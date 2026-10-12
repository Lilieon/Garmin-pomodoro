using Toybox.Application as App;
using Toybox.Attention as Attention;
using Toybox.Lang as Lang;
using Toybox.Math as Math;
using Toybox.Time as Time;

// Entry lifecycle + pomodoro session persistence.
// Work phases only are logged; pause splits the entry (close now, reopen later).
// All persisted dictionaries use String keys and String phase values.
class EntryLog {
    var session;
    var openEntry;
    hidden var sync;

    function initialize(syncObj) {
        sync = syncObj;
        session = App.Storage.getValue("session");
        openEntry = App.Storage.getValue("openEntry");
        retroClose();
    }

    function hasActiveSession() {
        return session != null;
    }

    function now() {
        return Time.now().value().toNumber();
    }

    function state() {
        if (session == null) {
            return null;
        }
        var remaining;
        if (session.get("pausedRemaining") != null) {
            remaining = session.get("pausedRemaining");
        } else {
            remaining = session.get("phaseEnd") - now();
            if (remaining < 0) {
                remaining = 0;
            }
        }
        return {"phase" => session.get("phase"),
                "project" => session.get("project"),
                "paused" => (session.get("pausedRemaining") != null),
                "remaining" => remaining,
                "queued" => sync.queuedCount()} as Lang.Dictionary;
    }

    function startSession(project) {
        var mins = (App.getApp() as PomodoroApp).setting("workMin");
        startWork(project, mins * 60);
    }

    function tick() {
        if (session == null || session.get("pausedRemaining") != null) {
            return false;
        }
        if (now() < session.get("phaseEnd")) {
            return false;
        }
        var app = App.getApp() as PomodoroApp;
        if (session.get("phase").equals("work")) {
            if (openEntry != null) {
                closeEntry(session.get("phaseEnd"));
            }
            vibrate();
            startBreak(app.setting("breakMin") * 60);
        } else {
            vibrate();
            startWork(session.get("project"), app.setting("workMin") * 60);
        }
        return true;
    }

    function pause() {
        if (session == null || !session.get("phase").equals("work") || openEntry == null) {
            return;
        }
        closeEntry(now());
        session.put("pausedRemaining", session.get("phaseEnd") - now());
        persist();
    }

    function resume() {
        if (session == null || session.get("pausedRemaining") == null) {
            return;
        }
        session.put("phaseEnd", now() + session.get("pausedRemaining"));
        session.put("pausedRemaining", null);
        open(session.get("project"));
        persist();
    }

    function skip() {
        if (session == null) {
            return;
        }
        var app = App.getApp() as PomodoroApp;
        if (session.get("phase").equals("work")) {
            if (openEntry != null) {
                closeEntry(now());
            }
            startBreak(app.setting("breakMin") * 60);
        } else {
            startWork(session.get("project"), app.setting("workMin") * 60);
        }
    }

    function stopSession() {
        if (openEntry != null) {
            closeEntry(now());
        }
        session = null;
        persist();
    }

    hidden function startWork(project, durSec) {
        session = {"phase" => "work", "project" => project,
                   "phaseEnd" => now() + durSec, "pausedRemaining" => null};
        open(project);
        persist();
    }

    hidden function startBreak(durSec) {
        session = {"phase" => "break", "project" => session.get("project"),
                   "phaseEnd" => now() + durSec, "pausedRemaining" => null};
        persist();
    }

    // Relaunch mid-phase: close at scheduled end (arithmetic — no drift, no duplicate).
    hidden function retroClose() {
        if (session == null || session.get("pausedRemaining") != null) {
            return;
        }
        var app = App.getApp() as PomodoroApp;
        if (session.get("phase").equals("work") && openEntry != null
            && now() >= session.get("phaseEnd")) {
            closeEntry(session.get("phaseEnd"));
            startBreak(app.setting("breakMin") * 60);
        } else if (session.get("phase").equals("break")
            && now() >= session.get("phaseEnd")) {
            startWork(session.get("project"), app.setting("workMin") * 60);
        }
    }

    hidden function open(project) {
        openEntry = {"key" => nextKey(), "t1" => now(), "project" => project};
        App.Storage.setValue("openEntry", openEntry);
        sync.flush();
    }

    hidden function closeEntry(t2) {
        var e = openEntry;
        sync.enqueue({"key" => e.get("key"), "t1" => e.get("t1"), "t2" => t2,
                      "ds" => "#" + e.get("project") + " focus",
                      "mt" => t2, "st" => 0});
        openEntry = null;
        App.Storage.deleteValue("openEntry");
    }

    // CIQ has no UUID: <epochSec>-<counter>-<rand> (uniqueness is all TT needs)
    hidden function nextKey() {
        var c = App.Storage.getValue("counter");
        if (c == null) {
            c = 0;
        }
        c = c + 1;
        App.Storage.setValue("counter", c);
        return now().toString() + "-" + c.toString() + "-" + (Math.rand() % 10000).toString();
    }

    function persist() {
        App.Storage.setValue("session", session);
        if (openEntry == null) {
            App.Storage.deleteValue("openEntry");
        } else {
            App.Storage.setValue("openEntry", openEntry);
        }
    }

    hidden function vibrate() {
        Attention.vibrate([new Attention.VibeProfile(400, 100),
                           new Attention.VibeProfile(150, 0),
                           new Attention.VibeProfile(400, 100)]);
    }
}
