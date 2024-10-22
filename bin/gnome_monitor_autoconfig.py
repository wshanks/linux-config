#!/usr/bin/env python
"""Script to automatically enable only the external monitor in GNOME"""

import re
import time
from subprocess import DEVNULL, PIPE, Popen, run


MONITOR_MATCH = re.compile(r"^Monitor \[ (?P<name>.*) \] (?P<state>.*)$")
BUILTIN_MONITOR = "eDP-1"


def ensure_external():
    """Ensure external monitor is used when present"""
    for _ in range(10):
        proc = run(
            ["gnome-monitor-config", "list"], text=True, check=False, capture_output=True
        )
        if proc.returncode != 0:
            print("gnome-monitor-config list failed!")
            print("stdout:")
            print(proc.stdout)
            print("stderr:")
            print(proc.stderr)
            time.sleep(2)
        else:
            break
    monitor_config = proc.stdout
    monitors = {
        match_.group("name"): match_.group("state")
        for line in monitor_config.splitlines()
        if (match_ := MONITOR_MATCH.match(line))
    }

    print(f"Monitor states: {monitors}")
    if len(monitors) != 2 or monitors.get(BUILTIN_MONITOR, "OFF") == "OFF":
        return

    other_monitor = next(m for m in monitors if m != BUILTIN_MONITOR)
    print(f"Activating {other_monitor}")
    for _ in range(3):
        proc = run(
            ["gnome-monitor-config", "set", "-LpM", other_monitor],
            check=False,
            capture_output=True,
            text=True,
        )
        if proc.returncode == 0:
            break
        else:
            print(f"Error activating {other_monitor}")
            print("stdout:")
            print(proc.stdout)
            print("stderr:")
            print(proc.stderr)
            time.sleep(0.5)
    else:
        raise RuntimeError("Unrecoverable errors encountered activating {other_monitor}")


def main():
    """Main logic"""
    # Do initial monitor set up before listening for changes

    ensure_external()
    match_expr = ",".join(
        [
            "type='signal'",
            "path='/org/gnome/Mutter/DisplayConfig'",
            "interface='org.gnome.Mutter.DisplayConfig'",
            "member='MonitorsChanged'",
        ]
    )
    with Popen(
        [
            "dbus-monitor",
            "--session",
            match_expr,
        ],
        text=True,
        stdout=PIPE,
    ) as proc:
        while True:
            msg = proc.stdout.readline()
            if "MonitorsChanged" not in msg:
                # Skip initial output
                continue
            ensure_external()


if __name__ == "__main__":
    main()
