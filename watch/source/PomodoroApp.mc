using Toybox.Application as App;
using Toybox.Lang as Lang;
using Toybox.System as Sys;
using Toybox.WatchUi as Ui;

class PomodoroApp extends App.AppBase {
    var model;
    var sync;

    function initialize() {
        App.AppBase.initialize();

        sync = new SyncClient();
        model = new EntryLog(sync);
    }

    function getInitialView() {

        if (model.hasActiveSession()) {
            return [new TimerView(), new TimerDelegate()] as Lang.Array;
        }
        return [new ProjectPickerView(), new ProjectPickerDelegate()] as Lang.Array;
    }

    function setting(key) {
        return App.Properties.getValue(key);
    }

    function onStop(state) {
        model.persist();
        App.AppBase.onStop(state);
    }
}
