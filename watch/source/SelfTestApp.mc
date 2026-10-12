using Toybox.Application as App;
using Toybox.Lang as Lang;
using Toybox.System as Sys;
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

class SelfTestView extends Ui.View {
    function initialize() {
        Ui.View.initialize();
    }

    function onUpdate(dc) {
        dc.clear();
    }
}
