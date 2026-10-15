import json
import shutil
import subprocess
import sys

TIMEOUT = 10
TOGGLE_TIMEOUT = 45
FOREIGN_DEVICES = {"wt0", "tailscale0"}
NM_TYPES = {"vpn", "wireguard"}
NETBIRD_APP = "netbird-ui"

Entry = dict[str, object]


def run(args: list[str], timeout: int = TIMEOUT) -> str:
    result = subprocess.run(
        args, capture_output=True, text=True, timeout=timeout, check=False
    )
    if result.returncode != 0:
        message = (result.stderr.strip() or result.stdout.strip()).splitlines()
        raise RuntimeError(
            message[-1] if message else f"{args[0]} exited {result.returncode}"
        )
    return result.stdout


def split_terse(line: str) -> list[str]:
    fields, current, escaped = [], "", False
    for char in line:
        if escaped:
            current += char
            escaped = False
        elif char == "\\":
            escaped = True
        elif char == ":":
            fields.append(current)
            current = ""
        else:
            current += char
    fields.append(current)
    return fields


def nm_external_devices() -> set[str]:
    external = set(FOREIGN_DEVICES)
    for line in run(["nmcli", "-t", "-f", "DEVICE,STATE", "device"]).splitlines():
        fields = split_terse(line)
        if len(fields) >= 2 and "externally" in fields[1]:
            external.add(fields[0])
    return external


def nm_address(uuid: str) -> str:
    try:
        output = run(["nmcli", "-g", "IP4.ADDRESS", "connection", "show", "uuid", uuid])
    except (OSError, subprocess.SubprocessError, RuntimeError):
        return ""
    first = output.strip().split("|")[0].strip()
    return first.split("/")[0]


def nm_flavour(kind: str, uuid: str) -> str:
    if kind == "wireguard":
        return "WireGuard"
    try:
        service = run(
            ["nmcli", "-g", "vpn.service-type", "connection", "show", "uuid", uuid]
        ).strip()
    except (OSError, subprocess.SubprocessError, RuntimeError):
        return "VPN"
    name = service.rsplit(".", 1)[-1]
    return {"openvpn": "OpenVPN", "openconnect": "OpenConnect", "vpnc": "Cisco"}.get(
        name, name.capitalize() or "VPN"
    )


def nm_entries() -> list[Entry]:
    external = nm_external_devices()
    found: list[Entry] = []
    output = run(["nmcli", "-t", "-f", "NAME,UUID,TYPE,DEVICE,STATE", "connection"])
    for line in output.splitlines():
        fields = split_terse(line)
        if len(fields) < 5:
            continue
        name, uuid, kind, device, state = fields[:5]
        if kind not in NM_TYPES or name in FOREIGN_DEVICES or device in external:
            continue
        active = state == "activated"
        found.append(
            {
                "kind": "nm",
                "id": uuid,
                "name": name,
                "flavour": nm_flavour(kind, uuid),
                "active": active,
                "pending": state in {"activating", "deactivating"},
                "device": device,
                "detail": nm_address(uuid) if active else "",
                "toggle": "cli",
            }
        )
    return found


def netbird_entry() -> Entry | None:
    if not shutil.which("netbird"):
        return None
    entry: Entry = {
        "kind": "netbird",
        "id": "netbird",
        "name": "NetBird",
        "flavour": "",
        "active": False,
        "pending": False,
        "device": "wt0",
        "detail": "",
        "toggle": "cli",
        "app": NETBIRD_APP,
    }
    try:
        data = json.loads(run(["netbird", "status", "--json"]))
    except (OSError, subprocess.SubprocessError, RuntimeError, ValueError) as error:
        entry["detail"] = "daemon unavailable"
        entry["toggle"] = "app"
        entry["error"] = str(error)
        return entry
    state = str(data.get("daemonStatus", ""))
    management = data.get("management") or {}
    peers = data.get("peers") or {}
    active = state == "Connected" and bool(management.get("connected"))
    entry["active"] = active
    entry["pending"] = state == "Connecting"
    entry["state"] = state
    entry["fqdn"] = data.get("fqdn", "")
    if state in {"NeedsLogin", "LoginFailed", "SessionExpired"}:
        entry["toggle"] = "app"
        entry["detail"] = "login required"
    elif active:
        address = str(data.get("netbirdIp", "")).split("/")[0]
        total = int(peers.get("total", 0))
        connected = int(peers.get("connected", 0))
        count = f"{connected}/{total}" if connected else str(total)
        entry["detail"] = " · ".join(
            part for part in (address, f"{count} peers" if total else "") if part
        )
    elif state == "Connected":
        entry["detail"] = "management offline"
    return entry


def status() -> None:
    entries: list[Entry] = []
    errors = []
    try:
        entries.extend(nm_entries())
    except (OSError, subprocess.SubprocessError, RuntimeError) as error:
        errors.append(f"nmcli: {error}")
    entry = netbird_entry()
    if entry is not None:
        entries.append(entry)
    result: dict[str, object] = {"vpns": entries}
    if errors:
        result["error"] = "; ".join(errors)
    emit(result)


def toggle(up: bool, kind: str, ident: str) -> None:
    if kind == "nm":
        run(
            ["nmcli", "--wait", str(TOGGLE_TIMEOUT), "connection"]
            + (["up"] if up else ["down"])
            + ["uuid", ident],
            timeout=TOGGLE_TIMEOUT + 5,
        )
    elif kind == "netbird":
        run(
            ["netbird", "up", "--no-browser"] if up else ["netbird", "down"],
            timeout=TOGGLE_TIMEOUT,
        )
    else:
        raise RuntimeError(f"unknown kind {kind}")


def emit(result: dict[str, object]) -> None:
    json.dump(result, sys.stdout, separators=(",", ":"))
    sys.stdout.write("\n")


def main() -> None:
    args = sys.argv[1:]
    if args[:1] == ["status"] or not args:
        status()
        return
    if len(args) != 3 or args[0] not in {"up", "down"}:
        emit({"ok": False, "error": "usage: vpn.py status | up|down <kind> <id>"})
        sys.exit(2)
    try:
        toggle(args[0] == "up", args[1], args[2])
    except (OSError, subprocess.SubprocessError, RuntimeError) as error:
        emit({"ok": False, "error": f"{args[1]}: {error}"})
        return
    emit({"ok": True})


if __name__ == "__main__":
    main()
