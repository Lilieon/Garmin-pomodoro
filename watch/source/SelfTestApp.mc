using Toybox.Application as App;
using Toybox.Lang as Lang;
using Toybox.System as Sys;
using Toybox.Timer as Timer;
using Toybox.WatchUi as Ui;

// Selftest entry point — see watch/selftest.jungle. Prints results to
// monkeydo stdout, then shows a black screen (read the console, not the UI).
class SelfTestApp extends App.AppBase {
    function initialize() {
        App.AppBase.initialize();
        var failures = PomodoroSelfTest.runAll();
        Sys.println(failures == 0 ? "TT: SELFTEST OK" : "TT: SELFTEST FAILED");
    }

    function getInitialView() {
        return [new SelfTestView(), new Ui.InputDelegate()] as Lang.Array;
    }
}

// E2E (runs only when ttToken setting is non-empty):
// 1. enqueue one record → flush → PUT
// 2. after response: re-enqueue the SAME key (duplicate-send gate)
// 3. after response: report queue size — 0 means TT accepted both idempotently
class E2EDriver {
    static var instance;
    var sync;
    var step = 0;
    var key;
    var timer;

    static function start() {
        var token = App.Properties.getValue("ttToken");
        if (token == null || token.equals("")) {
            Sys.println("TT: e2e skipped (no token)");
            return;
        }
        instance = new E2EDriver();
        instance.begin();
    }

    function begin() {
        sync = new SyncClient();
        var t = Sys.getTimer() / 1000;
        key = t.toString() + "-777-123";
        Sys.println("TT: e2e key=" + key);
        timer = new Timer.Timer();
        timer.start(method(:tick), 8000, true);
    }

    function tick() as Void {
        if (step == 0) {
            Sys.println("TT: e2e enqueue #1 (q=" + sync.queuedCount().toString() + ")");
            sync.enqueue({"key" => key, "t1" => 1760100000, "t2" => 1760100600,
                          "ds" => "#e2e focus", "mt" => 1760100600, "st" => 0});
            step = 1;
        } else if (step == 1) {
            Sys.println("TT: e2e after #1 q=" + sync.queuedCount().toString());
            Sys.println("TT: e2e enqueue #2 duplicate key");
            sync.enqueue({"key" => key, "t1" => 1760100000, "t2" => 1760100600,
                          "ds" => "#e2e focus", "mt" => 1760100600, "st" => 0});
            step = 2;
        } else {
            Sys.println("TT: e2e after duplicate q=" + sync.queuedCount().toString());
            Sys.println("TT: E2E DONE");
            timer.stop();
        }
    }
}

class SelfTestView extends Ui.View {
    function initialize() {
        Ui.View.initialize();
    }

    function onShow() {
        E2EDriver.start();
    }

    function onUpdate(dc) {
        dc.clear();
    }
}
