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
        var parsed = ProjectPicker.parse(App.Properties.getValue("projects"));
        projects = parsed[0];
        invalid = parsed[1];
        if (projects.size() == 0) {
            return;
        }
        var menu = new Ui.Menu2({:title => "Project?"});
        for (var i = 0; i < projects.size(); i++) {
            menu.addItem(new Ui.MenuItem(projects[i], null, projects[i], null));
        }
        if (invalid.size() > 0) {
            var skipped = "";
            for (var i = 0; i < invalid.size(); i++) {
                if (i > 0) {
                    skipped += ", ";
                }
                skipped += invalid[i];
            }
            menu.addItem(new Ui.MenuItem("skipped: " + skipped, null, "invalid", null));
        }
        Ui.pushView(menu, new ProjectMenuDelegate(), Ui.SLIDE_IMMEDIATE);
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

    function onSelect(item as Ui.MenuItem) as Void {
        var id = item.getId().toString();
        if (id.equals("invalid")) {
            return;
        }
        (App.getApp() as PomodoroApp).model.startSession(id);
        Ui.popView(Ui.SLIDE_IMMEDIATE);
        Ui.pushView(new TimerView(), new TimerDelegate(), Ui.SLIDE_UP);
    }
}

class ProjectPickerDelegate extends Ui.InputDelegate {
    function initialize() {
        Ui.InputDelegate.initialize();
    }
}

class ProjectPicker {
    static function parse(raw) {
        var valid = [];
        var invalid = [];
        if (raw != null) {
            var semi = splitOn(raw, ";");
            for (var i = 0; i < semi.size(); i++) {
                var lines = splitOn(semi[i], "\n");
                for (var j = 0; j < lines.size(); j++) {
                    var p = trim(lines[j]);
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
        }
        return [valid, invalid] as Lang.Array;
    }

    static function splitOn(s, sep) as Lang.Array {
        var out = [];
        var rest = s;
        var i = rest.find(sep);
        while (i != null) {
            out.add(rest.substring(0, i));
            rest = rest.substring(i + 1, rest.length());
            i = rest.find(sep);
        }
        out.add(rest);
        return out;
    }

    static function trim(s) {
        var start = 0;
        var end = s.length();
        while (start < end && isSpace(s.substring(start, start + 1))) {
            start += 1;
        }
        while (end > start && isSpace(s.substring(end - 1, end))) {
            end -= 1;
        }
        return s.substring(start, end);
    }

    static function isSpace(c) {
        return c.equals(" ") || c.equals("\t") || c.equals("\r");
    }

    static function validTag(s) {
        if (s.length() == 0) {
            return false;
        }
        var ok = "abcdefghijklmnopqrstuvwxyz0123456789-";
        for (var i = 0; i < s.length(); i++) {
            if (ok.find(s.substring(i, i + 1)) == null) {
                return false;
            }
        }
        return true;
    }
}
