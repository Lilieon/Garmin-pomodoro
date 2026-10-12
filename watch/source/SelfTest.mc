using Toybox.Lang as Lang;
using Toybox.System as Sys;

// Minimal assert harness — CIQ unit-test barrel is unavailable on device targets,
// so the selftest app prints results via Sys.println (read from monkeydo stdout).
class TT {
    static var passed = 0;
    static var failed = 0;

    static function reset() {
        passed = 0;
        failed = 0;
    }

    static function fail(what, expected, actual) {
        failed += 1;
        Sys.println("TT: FAIL " + what + " expected=" + fmt(expected) + " actual=" + fmt(actual));
    }

    static function ok(what) {
        passed += 1;
    }

    static function assertEqual(expected, actual, what) {
        if (expected == null || actual == null) {
            if (expected == null && actual == null) {
                ok(what);
            } else {
                fail(what, expected, actual);
            }
        } else if (expected.equals(actual)) {
            ok(what);
        } else {
            fail(what, expected, actual);
        }
    }

    static function assertTrue(cond, what) {
        if (cond == true) {
            ok(what);
        } else {
            fail(what, true, cond);
        }
    }

    static function assertFalse(cond, what) {
        assertTrue(cond == false, what);
    }

    static function summary() {
        Sys.println("TT: RESULTS passed=" + passed.toString() + " failed=" + failed.toString());
        return failed;
    }

    static function fmt(v) {
        if (v == null) {
            return "null";
        }
        return v.toString();
    }
}
