import importlib
import json
import os
import select
import signal
import subprocess
import sys
import time
from pathlib import Path

UNIT = "statusbar-lidhold.service"
ARM_SECONDS = int(os.environ.get("LIDHOLD_ARM_SECONDS", "900"))
HOLD_SECONDS = int(os.environ.get("LIDHOLD_HOLD_SECONDS", "3600"))
POLL_SECONDS = 2
HOLD_ACTION = "32"
SAVER = "power-saver"
GROUPS = ("AC", "Battery", "LowBattery")
CONFIG = "powerdevilrc"
STATE = (
    Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state"))
    / "statusbar"
    / "lidhold.json"
)
SCRIPT = os.path.abspath(__file__)
PYTHON = "/usr/bin/python3"
PROFILE_BUSES = (
    ("org.freedesktop.UPower.PowerProfiles", "/org/freedesktop/UPower/PowerProfiles"),
    ("net.hadess.PowerProfiles", "/net/hadess/PowerProfiles"),
)

State = dict[str, object]


def log(message: str) -> None:
    print(message, file=sys.stderr, flush=True)


def run(args: list[str], timeout: int = 10) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        args, capture_output=True, text=True, timeout=timeout, check=False
    )


def emit(result: dict[str, object]) -> None:
    json.dump(result, sys.stdout, separators=(",", ":"))
    sys.stdout.write("\n")


def load_state() -> State | None:
    try:
        return json.loads(STATE.read_text())
    except (OSError, ValueError):
        return None


def save_state(state: State) -> None:
    STATE.parent.mkdir(parents=True, exist_ok=True)
    tmp = STATE.with_suffix(".tmp")
    tmp.write_text(json.dumps(state))
    os.replace(tmp, STATE)


def read_lid_action(group: str) -> str | None:
    result = run(
        [
            "kreadconfig6",
            "--file",
            CONFIG,
            "--group",
            group,
            "--group",
            "SuspendAndShutdown",
            "--key",
            "LidAction",
        ]
    )
    value = result.stdout.strip()
    return value or None


def write_lid_action(group: str, value: str | None) -> None:
    args = [
        "kwriteconfig6",
        "--file",
        CONFIG,
        "--group",
        group,
        "--group",
        "SuspendAndShutdown",
        "--key",
        "LidAction",
    ]
    result = run(args + (["--delete"] if value is None else [value]))
    if result.returncode != 0:
        raise RuntimeError(f"kwriteconfig6 {group}: {result.stderr.strip()}")


def reload_powerdevil() -> None:
    result = run(
        [
            "busctl",
            "--user",
            "--timeout=20",
            "call",
            "org.kde.Solid.PowerManagement",
            "/org/kde/Solid/PowerManagement",
            "org.kde.Solid.PowerManagement",
            "refreshStatus",
        ],
        timeout=25,
    )
    if result.returncode != 0:
        log(f"refreshStatus failed: {result.stderr.strip()}")


def powerdevil_lid_action() -> int | None:
    result = run(
        [
            "busctl",
            "--user",
            "call",
            "org.kde.Solid.PowerManagement",
            "/org/kde/Solid/PowerManagement/Actions/HandleButtonEvents",
            "org.kde.Solid.PowerManagement.Actions.HandleButtonEvents",
            "lidAction",
        ]
    )
    parts = result.stdout.split()
    return int(parts[1]) if result.returncode == 0 and len(parts) == 2 else None


def system_property(bus: str, path: str, iface: str, name: str) -> str | None:
    result = run(
        [
            "busctl",
            "--system",
            "get-property",
            bus,
            path,
            iface,
            name,
        ]
    )
    if result.returncode != 0:
        return None
    parts = result.stdout.split(None, 1)
    return parts[1].strip().strip('"') if len(parts) == 2 else None


def lid_closed() -> bool | None:
    value = system_property(
        "org.freedesktop.UPower",
        "/org/freedesktop/UPower",
        "org.freedesktop.UPower",
        "LidIsClosed",
    )
    if value is not None:
        return value == "true"
    try:
        for state in Path("/proc/acpi/button/lid").glob("*/state"):
            return "closed" in state.read_text()
    except OSError:
        pass
    return None


def lid_present() -> bool:
    value = system_property(
        "org.freedesktop.UPower",
        "/org/freedesktop/UPower",
        "org.freedesktop.UPower",
        "LidIsPresent",
    )
    return value == "true"


def get_profile() -> str | None:
    for bus, path in PROFILE_BUSES:
        value = system_property(bus, path, bus, "ActiveProfile")
        if value:
            return value
    return None


def set_profile(profile: str) -> bool:
    for bus, path in PROFILE_BUSES:
        result = run(
            [
                "busctl",
                "--system",
                "set-property",
                bus,
                path,
                bus,
                "ActiveProfile",
                "s",
                profile,
            ]
        )
        if result.returncode == 0:
            return True
        log(f"set {profile} via {bus} failed: {result.stderr.strip()}")
    return False


def display_session() -> str:
    return run(
        ["loginctl", "show-user", str(os.getuid()), "-p", "Display", "--value"]
    ).stdout.strip()


def session_locked() -> bool | None:
    session = display_session()
    hint = (
        run(["loginctl", "show-session", session, "-p", "LockedHint", "--value"])
        if session
        else None
    )
    saver = run(
        [
            "busctl",
            "--user",
            "call",
            "org.freedesktop.ScreenSaver",
            "/ScreenSaver",
            "org.freedesktop.ScreenSaver",
            "GetActive",
        ]
    )
    answers = []
    if hint is not None and hint.returncode == 0:
        answers.append(hint.stdout.strip() == "yes")
    if saver.returncode == 0:
        answers.append(saver.stdout.strip() == "b true")
    return any(answers) if answers else None


def lock_session() -> None:
    session = display_session()
    result = run(["loginctl", "lock-session"] + ([session] if session else []))
    if result.returncode != 0:
        log(f"lock-session failed: {result.stderr.strip()}")


def unit_active() -> bool:
    return run(["systemctl", "--user", "is-active", "--quiet", UNIT]).returncode == 0


def restore() -> None:
    state = load_state()
    if state is None:
        return
    original = state.get("lid")
    held = state.get("held_profile")
    if isinstance(held, str):
        set_profile(held)
    keep = held if isinstance(held, str) else get_profile()
    if isinstance(original, dict):
        for group in GROUPS:
            value = original.get(group)
            write_lid_action(group, value if isinstance(value, str) else None)
    STATE.unlink(missing_ok=True)
    reload_powerdevil()
    if keep and get_profile() != keep:
        set_profile(keep)
    log("restored")


def hold_lid() -> State:
    if load_state() is not None:
        restore()
    original = {group: read_lid_action(group) for group in GROUPS}
    state: State = {
        "lid": original,
        "phase": "armed",
        "deadline": time.time() + ARM_SECONDS,
    }
    save_state(state)
    profile = get_profile()
    for group in GROUPS:
        write_lid_action(group, HOLD_ACTION)
    reload_powerdevil()
    if profile and get_profile() != profile:
        set_profile(profile)
    return state


class Inhibitor:
    def __init__(self) -> None:
        self.bus = None
        self.cookie: int | None = None

    def acquire(self) -> None:
        importlib.import_module("gi").require_version("Gio", "2.0")
        Gio = importlib.import_module("gi.repository.Gio")
        GLib = importlib.import_module("gi.repository.GLib")
        self.bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
        reply = self.bus.call_sync(
            "org.freedesktop.PowerManagement",
            "/org/freedesktop/PowerManagement/Inhibit",
            "org.freedesktop.PowerManagement.Inhibit",
            "Inhibit",
            GLib.Variant("(ss)", ("Statusbar", "Lid closed on purpose, staying awake")),
            GLib.VariantType("(u)"),
            Gio.DBusCallFlags.NONE,
            5000,
            None,
        )
        self.cookie = reply.unpack()[0]
        log(f"inhibited sleep, cookie {self.cookie}")

    def release(self) -> None:
        if self.bus is None or self.cookie is None:
            return
        Gio = importlib.import_module("gi.repository.Gio")
        GLib = importlib.import_module("gi.repository.GLib")
        try:
            self.bus.call_sync(
                "org.freedesktop.PowerManagement",
                "/org/freedesktop/PowerManagement/Inhibit",
                "org.freedesktop.PowerManagement.Inhibit",
                "UnInhibit",
                GLib.Variant("(u)", (self.cookie,)),
                None,
                Gio.DBusCallFlags.NONE,
                5000,
                None,
            )
        except GLib.Error as error:
            log(f"UnInhibit failed: {error.message}")
        self.cookie = None


def on_close(state: State, now: float) -> None:
    state["phase"] = "closed"
    state["closed_at"] = now
    state["held_profile"] = get_profile()
    save_state(state)
    set_profile(SAVER)
    lock_session()
    log(f"lid closed, held {state['held_profile']}")


class Cycle:
    def __init__(self) -> None:
        self.state: State = {}
        self.done = False

    def stop(self, *_: object) -> None:
        self.done = True

    def step(self, closed: bool | None, now: float, locked: bool | None = None) -> None:
        phase = self.state.get("phase")
        if phase == "armed":
            if closed:
                on_close(self.state, now)
            elif now >= float(str(self.state.get("deadline", 0))):
                log("expired")
                self.done = True
        elif phase == "closed":
            if closed is False:
                log("lid opened, waiting for unlock")
                restore()
                self.state["phase"] = "opened"
                self.state["opened_at"] = now
            elif self.held_too_long(now):
                log(f"held {HOLD_SECONDS}s, back to normal lid behaviour")
                self.done = True
        elif phase == "opened":
            if not locked:
                log("unlocked")
                self.done = True
            elif now - float(str(self.state.get("opened_at", now))) >= ARM_SECONDS:
                log(f"still locked {ARM_SECONDS}s after opening, releasing")
                self.done = True

    def tick(self) -> None:
        locked = session_locked() if self.state.get("phase") == "opened" else None
        self.step(lid_closed(), time.time(), locked)

    def held_too_long(self, now: float) -> bool:
        return now - float(str(self.state.get("closed_at", now))) >= HOLD_SECONDS

    def run(self) -> None:
        signal.signal(signal.SIGTERM, self.stop)
        signal.signal(signal.SIGINT, self.stop)
        if lid_closed():
            log("lid already closed, not arming")
            return
        watcher = None
        inhibitor = Inhibitor()
        try:
            self.state = hold_lid()
            inhibitor.acquire()
            log(f"armed for {ARM_SECONDS}s")
            watcher = subprocess.Popen(
                [
                    "gdbus",
                    "monitor",
                    "--system",
                    "--dest",
                    "org.freedesktop.UPower",
                    "--object-path",
                    "/org/freedesktop/UPower",
                ],
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
            )
            fd = watcher.stdout.fileno() if watcher.stdout else None
            self.tick()
            while not self.done:
                if fd is None:
                    time.sleep(POLL_SECONDS)
                elif select.select([fd], [], [], POLL_SECONDS)[0] and not os.read(
                    fd, 65536
                ):
                    fd = None
                self.tick()
        finally:
            if watcher is not None:
                watcher.terminate()
            inhibitor.release()
            restore()


def status() -> None:
    state = load_state()
    active = unit_active()
    if state is not None and not active:
        restore()
        state = None
    result: dict[str, object] = {
        "available": lid_present(),
        "armed": active and state is not None,
        "phase": (state or {}).get("phase", "idle") if active else "idle",
        "deadline": int(float(str((state or {}).get("deadline", 0))) * 1000),
        "closed": bool(lid_closed()),
    }
    emit(result)


def arm() -> None:
    if unit_active():
        emit({"ok": True})
        return
    if lid_closed():
        emit({"ok": False, "error": "Lid is closed"})
        return
    run(["systemctl", "--user", "reset-failed", UNIT])
    result = run(
        [
            "systemd-run",
            "--user",
            "--quiet",
            "--collect",
            f"--unit={UNIT}",
            "--description=Statusbar: don't sleep on next lid close",
            f"--setenv=LIDHOLD_ARM_SECONDS={ARM_SECONDS}",
            f"--setenv=LIDHOLD_HOLD_SECONDS={HOLD_SECONDS}",
            "-p",
            f"ExecStopPost={PYTHON} {SCRIPT} restore",
            "-p",
            "TimeoutStopSec=30",
            PYTHON,
            SCRIPT,
            "run",
        ]
    )
    if result.returncode != 0:
        emit({"ok": False, "error": result.stderr.strip() or "systemd-run failed"})
        return
    for _ in range(50):
        if load_state() is not None:
            break
        time.sleep(0.1)
    emit({"ok": True})


def disarm() -> None:
    if unit_active():
        run(["systemctl", "--user", "stop", UNIT], timeout=40)
    restore()
    emit({"ok": True})


def main() -> None:
    command = sys.argv[1] if len(sys.argv) > 1 else "status"
    if command == "status":
        status()
    elif command == "arm":
        arm()
    elif command == "disarm":
        disarm()
    elif command == "run":
        Cycle().run()
    elif command == "restore":
        restore()
    else:
        emit({"ok": False, "error": "usage: lidhold.py status|arm|disarm"})
        sys.exit(2)


if __name__ == "__main__":
    main()
