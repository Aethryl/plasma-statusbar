import json
import re
import subprocess
import sys
import time

TIMEOUT = 60
KINDS = {
    "security": "security",
    "bug fix": "bugfix",
    "bugfix": "bugfix",
    "enhancement": "enhancement",
}
LINE = re.compile(
    r"^(?P<kind>[A-Za-z][A-Za-z ]*?)\s{2,}(?P<nevra>\S+)\s+\((?P<repo>[^)]*)\)\s*$"
)


def run(args: list[str]) -> str:
    result = subprocess.run(
        args, capture_output=True, text=True, timeout=TIMEOUT, check=False
    )
    if result.returncode != 0 and not result.stdout.strip():
        message = result.stderr.strip().splitlines()
        raise RuntimeError(
            message[-1] if message else f"{args[0]} exited {result.returncode}"
        )
    return result.stdout


def split_nevra(nevra: str) -> tuple[str, str, str]:
    base, _, arch = nevra.rpartition(".")
    if not base:
        base, arch = nevra, ""
    parts = base.rsplit("-", 2)
    if len(parts) < 3:
        return base, "", arch
    name, version, release = parts
    return name, f"{version}-{release}", arch


def packages() -> list[dict[str, str]]:
    found = []
    for line in run(["pkcon", "get-updates", "--plain"]).splitlines():
        match = LINE.match(line)
        if not match or match["kind"].strip().lower() in {
            "status",
            "results",
            "transaction",
        }:
            continue
        label = match["kind"].strip()
        name, version, arch = split_nevra(match["nevra"])
        found.append(
            {
                "kind": KINDS.get(label.lower(), "other"),
                "label": label,
                "name": name,
                "version": version,
                "arch": arch,
                "repo": match["repo"],
            }
        )
    return found


def flatpaks() -> list[dict[str, str]]:
    found = []
    seen = set()
    for scope in ("--system", "--user"):
        output = run(
            [
                "flatpak",
                "remote-ls",
                scope,
                "--updates",
                "--columns=application,version,branch",
            ]
        )
        for line in output.splitlines():
            fields = [*line.split("\t"), "", ""]
            app, version, branch = (
                fields[0].strip(),
                fields[1].strip(),
                fields[2].strip(),
            )
            if not app or (app, branch) in seen:
                continue
            seen.add((app, branch))
            found.append(
                {"name": app, "version": version, "branch": branch, "scope": scope[2:]}
            )
    return found


def main() -> None:
    errors = []
    system: list[dict[str, str]] = []
    apps: list[dict[str, str]] = []
    try:
        system = packages()
    except (OSError, subprocess.SubprocessError, RuntimeError) as error:
        errors.append(f"pkcon: {error}")
    try:
        apps = flatpaks()
    except (OSError, subprocess.SubprocessError, RuntimeError) as error:
        errors.append(f"flatpak: {error}")

    order = {"security": 0, "bugfix": 1, "enhancement": 2, "other": 3}
    system.sort(key=lambda p: (order[p["kind"]], p["name"], p["arch"]))
    counts = dict.fromkeys(order, 0)
    for package in system:
        counts[package["kind"]] += 1

    result: dict[str, object] = {
        "total": len(system) + len(apps),
        "security": counts["security"],
        "counts": counts,
        "flatpak": len(apps),
        "packages": system,
        "flatpaks": apps,
        "checked": int(time.time()),
    }
    if errors:
        result["error"] = "; ".join(errors)
    json.dump(result, sys.stdout, separators=(",", ":"))
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
