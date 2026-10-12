using Toybox.Application as App;
using Toybox.Graphics as Gfx;
using Toybox.Lang as Lang;
using Toybox.Timer as Timer;
using Toybox.WatchUi as Ui;

class TimerView extends Ui.View {
    hidden var tick;

    function initialize() {
        Ui.View.initialize();
    }

    function onLayout(dc) {
    }

    function onShow() {
        tick = new Timer.Timer();
        tick.start(method(:onTick), 1000, true);
    }

    function onHide() {
        if (tick != null) {
            tick.stop();
        }
    }

    function onTick() as Void {
        var app = App.getApp() as PomodoroApp;
        app.model.tick();
        Ui.requestUpdate();
    }

    function onUpdate(dc) {
        var app = App.getApp() as PomodoroApp;
        var st = app.model.state();
        dc.clear();
        var w = dc.getWidth();
        var h = dc.getHeight();
        if (st == null) {
            dc.drawText(w / 2, h / 2, Gfx.FONT_SMALL, "Session ended",
                        Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
            return;
        }
        dc.drawText(w / 2, 45, Gfx.FONT_SMALL,
                    st.get("phase").equals("work") ? "FOCUS" : "BREAK",
                    Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText(w / 2, h / 2, Gfx.FONT_NUMBER_MEDIUM, fmt(st.get("remaining")),
                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
        if (st.get("paused")) {
            dc.drawText(w / 2, h / 2 + 45, Gfx.FONT_TINY, "paused",
                        Gfx.TEXT_JUSTIFY_CENTER);
        }
        dc.drawText(w / 2, h - 55, Gfx.FONT_SMALL, st.get("project"),
                    Gfx.TEXT_JUSTIFY_CENTER);
        var q = app.sync.queuedCount();
        if (q > 0) {
            dc.drawText(w / 2, h - 25, Gfx.FONT_TINY, "queued: " + q.toString(),
                        Gfx.TEXT_JUSTIFY_CENTER);
        }
    }

    hidden function fmt(sec) {
        if (sec < 0) {
            sec = 0;
        }
        var m = sec / 60;
        var s = sec % 60;
        return m.toString() + ":" + (s < 10 ? "0" + s.toString() : s.toString());
    }
}
