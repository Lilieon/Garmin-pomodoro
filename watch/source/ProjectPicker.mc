using Toybox.Application as App;
using Toybox.Graphics as Gfx;
using Toybox.Lang as Lang;
using Toybox.WatchUi as Ui;

class ProjectPickerView extends Ui.View {
    hidden var projects;
    hidden var invalid;

    function initialize() {
        Ui.View.initialize();
    }

    function onLayout(dc) {
    }

    function onShow() {
        var parsed = ProjectPicker.parse((App.getApp() as PomodoroApp).setting("projects"));
        projects = parsed[0];
        invalid = parsed[1];
        if (projects.size() == 0) {
            return;
        }
        var items = [];
        for (var i = 0; i < projects.size(); i++) {
            items.add(new Ui.MenuItem(projects[i], null, projects[i], null));
        }
        if (invalid.size() > 0) {
            items.add(new Ui.MenuItem("skipped: " + invalid.join(", "), null, "invalid", null));
        }
        Ui.pushView(new Ui.Menu2({:title => "Project?", :items => items}),
                    new ProjectMenuDelegate(), Ui.SLIDE_IMMEDIATE);
    }

    function onUpdate(dc) {
        dc.clear();
        var w = dc.getWidth();
        var h = dc.getHeight();
        if (projects != null && projects.size() == 0) {
            dc.drawText(w / 2, h / 2 - 20, Gfx.FONT_SMALL, "No projects.",
                        Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
            dc.drawText(w / 2, h / 2 + 20, Gfx.FONT_TINY, "Edit app settings",
                        Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
        }
    }
}

class ProjectMenuDelegate extends Ui.Menu2InputDelegate {
    function initialize() {
        Ui.Menu2InputDelegate.initialize();
    }

    function onSelect(item) {
        var id = item.getId().toString();
        if (id.equals("invalid")) {
            return true;
        }
        (App.getApp() as PomodoroApp).model.startSession(id);
        Ui.popView();
        Ui.pushView(new TimerView(), new TimerDelegate(), Ui.SLIDE_UP);
        return true;
    }
}

class ProjectPicker {
    static function parse(raw) {
        var valid = [];
        var invalid = [];
        if (raw == null) {
            return [valid, invalid] as Lang.Array;
        }
        var semi = raw.split(";");
        for (var i = 0; i < semi.size(); i++) {
            var lines = semi[i].split("\n");
            for (var j = 0; j < lines.size(); j++) {
                var p = lines[j].trim();
                if (p.equals("")) {
                    continue;
                }
                if (validTag(p)) {
                    valid.add(p);
                } else {
                    invalid.add(p);
                }
            }
        }
        return [valid, invalid] as Lang.Array;
    }

    static function validTag(s) {
        var ok = "abcdefghijklmnopqrstuvwxyz0123456789-";
        for (var i = 0; i < s.length(); i++) {
            if (ok.find(s.substring(i, i + 1)) == null) {
                return false;
            }
        }
        return true;
    }
}
