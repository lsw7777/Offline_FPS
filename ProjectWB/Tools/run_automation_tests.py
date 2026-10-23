#!/usr/bin/env python
"""
Project WB - unified test gate (third command in docs section 0.4).

Runs everything that can be verified without a human in front of a screen:

    python Tools/run_automation_tests.py [--filter ProjectWB.Core] [--verbose]

1. Python data + balance regression tests  (always)
2. UE Automation Tests                     (skipped with a loud warning if no engine is found)

Exit code 0 only if everything that *could* run passed.
"""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TOOLS = ROOT / "Tools"


def find_unreal_automation_cmd() -> list[str] | None:
    """Look for an UE EditorCmd executable in the usual places."""
    import os
    candidates: list[Path] = []
    for base in ("C:/Program Files/Epic Games", "D:/Epic Games", "D:/Unreal", "E:/Epic Games"):
        base_p = Path(base)
        if base_p.is_dir():
            for editor in base_p.glob("UE_5.*/Engine/Binaries/Win64/UnrealEditor-Cmd.exe"):
                candidates.append(editor)
    env_cmd = os.environ.get("WB_UE_EDITOR_CMD")
    if env_cmd:
        candidates.insert(0, Path(env_cmd))
    for c in candidates:
        if c.is_file():
            uproject = next(ROOT.glob("*.uproject"), None)
            if uproject is None:
                return None
            return [str(c), str(uproject), "-ExecCmds=Automation RunTests ProjectWB;Quit",
                    "-TestExit=Automation Test Queue Empty", "-unattended", "-nullrhi", "-NoSound"]
    return None


def run_python_tests(verbose: bool) -> int:
    cmd = [sys.executable, "-m", "unittest", "discover",
           "-s", str(TOOLS / "tests"), "-p", "test_*.py", "-t", str(TOOLS / "tests")]
    if verbose:
        cmd.append("-v")
    print("[1/2] python regression tests")
    return subprocess.call(cmd)


def run_ue_automation(filter_arg: str | None) -> int:
    cmd = find_unreal_automation_cmd()
    print("[2/2] UE automation tests")
    if cmd is None:
        print("      SKIPPED: 未找到 UnrealEditor-Cmd.exe（本机未安装 UE 5.5，或缺少 *.uproject）")
        print("      这是已知阻塞，见 Docs/STATE.md BLOCK-001；不计为失败。")
        return 0
    return subprocess.call(cmd)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--filter", default=None, help="UE automation test filter")
    ap.add_argument("--verbose", action="store_true")
    args = ap.parse_args()

    rc = run_python_tests(args.verbose)
    rc |= run_ue_automation(args.filter)
    print()
    print("ALL GREEN" if rc == 0 else "FAILED")
    return rc


if __name__ == "__main__":
    sys.exit(main())
