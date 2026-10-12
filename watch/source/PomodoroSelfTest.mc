using Toybox.Application as App;
using Toybox.Lang as Lang;
using Toybox.System as Sys;
using Toybox.Time as Time;

// Logic tests: run via the SelfTestApp entry (selftest.jungle).
// Covers plan gates: pause-split contiguity, retro-close at scheduled end,
// queue cap, key shape, JSON record shape, tag validation.
class PomodoroSelfTest {
    static function runAll() {
        TT.reset();
        testSplitOn();
        testTrim();
        testValidTag();
        testParseSettings();
        testRecordJson();
        testStartOpenClose();
        testKeyShape();
        testPauseSplitContiguous();
        testSkipWorkToBreak();
        testTickTransition();
        testRetroCloseOnRelaunch();
        testPausedStateSurvivesRelaunch();
        testQueueCap();
        return TT.summary();
    }

    static function clean() {
        var size = App.Storage.getValue("qsize");
        if (size != null) {
            for (var i = 0; i < size; i++) {
                App.Storage.deleteValue("q" + i.toString());
            }
            App.Storage.deleteValue("qsize");
        }
        App.Storage.deleteValue("session");
        App.Storage.deleteValue("openEntry");
        App.Storage.deleteValue("counter");
    }

    static function freshModel() {
        clean();
        return new EntryLog(new SyncClient());
    }

    // --- pure helpers (ProjectPicker) ---

    static function testSplitOn() {
        var parts = ProjectPicker.splitOn("a;b;;c", ";");
        TT.assertEqual(4, parts.size(), "splitOn count");
        TT.assertEqual("a", parts[0], "splitOn first");
        TT.assertEqual("", parts[2], "splitOn empty");
        TT.assertEqual("c", parts[3], "splitOn last");
        var none = ProjectPicker.splitOn("xyz", ";");
        TT.assertEqual(1, none.size(), "splitOn no-sep count");
        TT.assertEqual("xyz", none[0], "splitOn no-sep value");
    }

    static function testTrim() {
        TT.assertEqual("x", ProjectPicker.trim(" x "), "trim spaces");
        TT.assertEqual("x", ProjectPicker.trim("\tx\t\r"), "trim tabs");
        TT.assertEqual("", ProjectPicker.trim("   "), "trim all");
    }

    static function testValidTag() {
        TT.assertTrue(ProjectPicker.validTag("abc-123"), "tag abc-123");
        TT.assertTrue(ProjectPicker.validTag("focus"), "tag focus");
        TT.assertFalse(ProjectPicker.validTag("Abc"), "tag uppercase rejected");
        TT.assertFalse(ProjectPicker.validTag("a b"), "tag space rejected");
        TT.assertFalse(ProjectPicker.validTag("a_b"), "tag underscore rejected");
        TT.assertFalse(ProjectPicker.validTag(""), "tag empty rejected");
    }

    static function testParseSettings() {
        var parsed = ProjectPicker.parse("focus\nadmin; ops\n X ");
        var valid = parsed[0];
        var invalid = parsed[1];
        TT.assertEqual(3, valid.size(), "parse valid count");
        TT.assertEqual("focus", valid[0], "parse valid 0");
        TT.assertEqual("admin", valid[1], "parse valid 1");
        TT.assertEqual("ops", valid[2], "parse valid 2");
        TT.assertEqual(1, invalid.size(), "parse invalid count");
        TT.assertEqual("X", invalid[0], "parse invalid 0");
    }

    // --- SyncClient ---

    static function testQueueCap() {
        clean();
        var sync = new SyncClient();
        for (var i = 0; i < 502; i++) {
            sync.enqueue({"key" => "k" + i.toString(), "t1" => i, "t2" => i + 1,
                          "ds" => "#x focus", "mt" => i + 1, "st" => 0});
        }
        TT.assertEqual(500, sync.queuedCount(), "queue capped at 500");
        TT.assertEqual("k501", sync.record(sync.queuedCount() - 1).get("key"),
                       "queue dropped oldest");
    }

    static function testRecordJson() {
        clean();
        var sync = new SyncClient();
        TT.assertEqual(
            "{\"key\":\"abc\",\"t1\":10,\"t2\":20,\"ds\":\"#focus focus\",\"mt\":20,\"st\":0}",
            sync.recordJson({"key" => "abc", "t1" => 10, "t2" => 20,
                             "ds" => "#focus focus", "mt" => 20, "st" => 0}),
            "recordJson shape");
    }

    // --- EntryLog lifecycle ---

    static function testStartOpenClose() {
        var model = freshModel();
        TT.assertFalse(model.hasActiveSession(), "no session at start");
        model.startWork("focus", 1500);
        TT.assertTrue(model.hasActiveSession(), "session after start");
        TT.assertTrue(model.openEntry != null, "open entry after start");
        TT.assertEqual("focus", model.openEntry.get("project"), "open entry project");
        var st = model.state();
        TT.assertEqual("work", st.get("phase"), "phase work");
        TT.assertTrue(st.get("remaining") <= 1500, "remaining <= duration");
        model.stopSession();
        TT.assertFalse(model.hasActiveSession(), "no session after stop");
        TT.assertEqual(1, model.sync.queuedCount(), "one record queued");
        var rec = model.sync.record(0);
        TT.assertEqual("#focus focus", rec.get("ds"), "record ds");
        TT.assertEqual(0, rec.get("st"), "record st zero");
        TT.assertTrue(rec.get("t2") >= rec.get("t1"), "record interval ordered");
    }

    static function testKeyShape() {
        var model = freshModel();
        model.startWork("focus", 60);
        var key = model.openEntry.get("key");
        var parts = ProjectPicker.splitOn(key, "-");
        TT.assertEqual(3, parts.size(), "key has 3 components");
        TT.assertEqual(1, parts[1].toNumber(), "counter starts at 1");
        model.pause();
        model.resume();
        var key2 = model.openEntry.get("key");
        var parts2 = ProjectPicker.splitOn(key2, "-");
        TT.assertEqual(2, parts2[1].toNumber(), "counter increments");
        TT.assertTrue(!key.equals(key2), "keys unique");
    }

    // Plan §5.4: pause splits the entry — two contiguous-but-split intervals
    static function testPauseSplitContiguous() {
        var model = freshModel();
        model.startWork("focus", 1500);
        var t1 = model.openEntry.get("t1");
        model.pause();
        TT.assertTrue(model.openEntry == null, "entry closed on pause");
        TT.assertTrue(model.state().get("paused"), "state paused");
        model.resume();
        var second = model.openEntry;
        TT.assertTrue(second != null, "new entry on resume");
        TT.assertTrue(second.get("t1") >= t1, "second entry starts later");
        model.stopSession();
        TT.assertEqual(2, model.sync.queuedCount(), "two records after split");
        var firstRec = model.sync.record(0);
        var secondRec = model.sync.record(1);
        TT.assertEqual(firstRec.get("t2"), secondRec.get("t1"),
                       "split intervals contiguous");
        TT.assertEqual(firstRec.get("ds"), secondRec.get("ds"),
                       "split records same ds");
    }

    static function testSkipWorkToBreak() {
        var model = freshModel();
        model.startWork("focus", 1500);
        model.skip();
        TT.assertEqual("break", model.state().get("phase"), "skip work->break");
        TT.assertEqual(1, model.sync.queuedCount(), "work record queued on skip");
        model.skip();
        TT.assertEqual("work", model.state().get("phase"), "skip break->work");
        TT.assertTrue(model.openEntry != null, "new work entry after break skip");
        model.stopSession();
        TT.assertEqual(2, model.sync.queuedCount(), "two records after skips");
    }

    static function testTickTransition() {
        var model = freshModel();
        model.startWork("focus", 2);
        TT.assertFalse(model.tick(), "tick before expiry is a no-op");
        model.session.put("phaseEnd", model.now() - 5);
        TT.assertTrue(model.tick(), "tick fires on expiry");
        TT.assertEqual("break", model.state().get("phase"), "tick work->break");
        model.session.put("phaseEnd", model.now() - 5);
        TT.assertTrue(model.tick(), "tick fires on break expiry");
        TT.assertEqual("work", model.state().get("phase"), "tick break->work");
        model.stopSession();
        TT.assertEqual(2, model.sync.queuedCount(), "two records after ticks");
    }

    // Plan rule 4: exit mid-phase → relaunch retro-closes at scheduled end
    static function testRetroCloseOnRelaunch() {
        clean();
        var model = new EntryLog(new SyncClient());
        model.startWork("focus", 1500);
        // simulate "app exited mid-phase, phaseEnd passed while away":
        // entry actually started 3600s ago, was due to end 2100s ago
        var oldT1 = model.now() - 3600;
        var scheduledEnd = oldT1 + 1500;
        model.openEntry.put("t1", oldT1);
        model.session.put("phaseEnd", scheduledEnd);
        model.persist();
        var relaunched = new EntryLog(new SyncClient());
        TT.assertEqual("break", relaunched.state().get("phase"),
                       "relaunch enters break after expired work");
        TT.assertEqual(1, relaunched.sync.queuedCount(),
                       "expired entry enqueued on relaunch");
        var rec = relaunched.sync.record(0);
        TT.assertEqual(scheduledEnd, rec.get("t2"), "retro-closed at scheduled end");
        TT.assertEqual(oldT1, rec.get("t1"), "retro t1 preserved");
        TT.assertEqual(1500, rec.get("t2") - rec.get("t1"), "full phase duration logged");
        relaunched.stopSession();
    }

    static function testPausedStateSurvivesRelaunch() {
        clean();
        var model = new EntryLog(new SyncClient());
        model.startWork("focus", 1500);
        model.pause();
        var remaining = model.state().get("remaining");
        var relaunched = new EntryLog(new SyncClient());
        var st = relaunched.state();
        TT.assertTrue(st.get("paused"), "pause survives relaunch");
        TT.assertEqual(remaining, st.get("remaining"), "remaining preserved");
        relaunched.stopSession();
        TT.assertEqual(1, relaunched.sync.queuedCount(),
                       "paused work produced one record");
    }
}
