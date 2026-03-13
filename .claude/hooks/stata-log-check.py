#!/usr/bin/env python3
"""
PostToolUse hook: checks Stata .log files for r(xxx) errors after Stata execution.
Reads tool invocation JSON from stdin. Only activates when the command contains
StataMP or runs a .do file. Informational only (exit 0 always).
"""

import json
import re
import sys
from pathlib import Path


def main():
    # Read stdin JSON
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return  # Not valid JSON, skip silently

    # Extract the command that was run
    command = ""
    if isinstance(data, dict):
        tool_input = data.get("tool_input", {})
        if isinstance(tool_input, dict):
            command = tool_input.get("command", "")
        elif isinstance(tool_input, str):
            command = tool_input

    # Only activate for Stata commands
    if "StataMP" not in command and ".do" not in command and "run-stata" not in command:
        return

    # Use CLAUDE_PROJECT_DIR for absolute paths (fixes CWD != project root)
    import os
    project = Path(os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd()))

    # Find the most recent .log file — prefer output/logs/ (canonical location)
    log_files = list(project.glob("**/output/logs/*.log"))
    if not log_files:
        # Fallback: check project root (Stata -e mode artifact)
        log_files = list(project.glob("*.log"))

    if not log_files:
        print("[Stata Log Check] No .log files found in project tree.")
        return

    # Sort by modification time, most recent first
    log_files.sort(key=lambda p: p.stat().st_mtime, reverse=True)
    latest_log = log_files[0]

    # Read and scan for errors
    try:
        log_content = latest_log.read_text(encoding="utf-8", errors="replace")
    except OSError as e:
        print(f"[Stata Log Check] Could not read {latest_log}: {e}")
        return

    # Match only standalone r(xxx) error lines — avoids false positives from
    # legitimate Stata text that happens to contain "r(digits)" inline.
    error_pattern = re.compile(r"^r\((\d+)\);?\s*$", re.MULTILINE)
    errors_found = error_pattern.findall(log_content)

    if errors_found:
        unique_errors = sorted(set(errors_found))
        print(f"[Stata Log Check] WARNING: Errors found in {latest_log}:")
        for err_code in unique_errors:
            count = errors_found.count(err_code)
            print(f"  r({err_code}) - {count} occurrence(s)")
        print(f"  Total: {len(errors_found)} error(s) across {len(unique_errors)} unique code(s).")
        print(f"  Review the log file: {latest_log}")
    else:
        print(f"[Stata Log Check] Clean: no r(xxx) errors in {latest_log}")


if __name__ == "__main__":
    main()
