using Toybox.Application as App;
using Toybox.Lang as Lang;
using Toybox.WatchUi as Ui;

class TimerDelegate extends Ui.InputDelegate {
    function initialize() {
        Ui.InputDelegate.initialize();
    }

    function onSelect() {
        showMenu();
        return true;
    }

    function onTap(x, y) {
        showMenu();
        return true;
    }

    hidden function showMenu() {
        var app = App.getApp() as PomodoroApp;
        var st = app.model.state();
        if (st == null) {
            return;
        }
        var items = [];
        if (st.get("phase").equals("work")) {
            if (st.get("paused")) {
                items.add(new Ui.MenuItem("Resume", null, "resume", null));
            } else {
                items.add(new Ui.MenuItem("Pause", null, "pause", null));
            }
        }
        items.add(new Ui.MenuItem("Skip", null, "skip", null));
        items.add(new Ui.MenuItem("End session", null, "stop", null));
        Ui.pushView(new Ui.Menu2({:title => st.get("project"), :items => items}),
                    new StopMenuDelegate(), Ui.SLIDE_UP);
    }
}

class StopMenuDelegate extends Ui.Menu2InputDelegate {
    function initialize() {
        Ui.Menu2InputDelegate.initialize();
    }

    function onSelect(item) {
        var app = App.getApp() as PomodoroApp;
        var id = item.getId().toString();
        if (id.equals("pause")) {
            app.model.pause();
        } else if (id.equals("resume")) {
            app.model.resume();
        } else if (id.equals("skip")) {
            app.model.skip();
        } else if (id.equals("stop")) {
            app.model.stopSession();
            Ui.popView();
            Ui.popView();
            Ui.requestUpdate();
            return true;
        }
        Ui.popView();
        Ui.requestUpdate();
        return true;
    }
}
