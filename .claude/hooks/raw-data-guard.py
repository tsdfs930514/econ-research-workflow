#!/usr/bin/env python3
"""
raw-data-guard.py — PostToolUse hook: detect unauthorized modifications to data/raw/.
Catches bypass via Python/R scripts that Claude might execute through Bash.

Defence layer 2 (deny rules = layer 1, filesystem attrib +R = layer 3).

Workflow:
  1. Early exit if the Bash command doesn't touch data-related paths
  2. First run  → save baseline snapshot (file list + sizes + SHA-256 hashes)
  3. Later runs → compare current state against baseline
  4. If any file modified/deleted → print loud warning (exit 0 — detection only)
  5. New files are allowed (snapshot updates to include them)

Snapshot format v2: each entry has {size, hash} (SHA-256 hex digest).
Old v1 snapshots (with mtime_ns) are auto-migrated on first run.
"""
import hashlib
import json
import os
import sys
from pathlib import Path

SNAPSHOT_VERSION = 2

# Commands containing any of these keywords get the full data/raw check.
# Everything else exits early to avoid expensive scans on unrelated commands.
DATA_KEYWORDS = (
    "data", "raw", "csv", "dta", "xlsx", "xls", "parquet", "feather",
    "sas7bdat", "sav", "rds", "rda", "fwf", "tsv", "json",
    "python", "Rscript", "stata", "sas", "rm", "del", "move", "mv",
    "copy", "cp", "rename", "ren", "shutil", "os.remove", "unlink",
)


def file_hash(path: Path) -> str:
    """SHA-256 hex digest of file contents. Falls back to size-only on permission errors."""
    h = hashlib.sha256()
    try:
        h.update(path.read_bytes())
    except PermissionError:
        # Antivirus or indexer lock — fall back to size-only fingerprint
        try:
            return f"size-only:{path.stat().st_size}"
        except OSError:
            return "unreadable"
    except OSError:
        return "unreadable"
    return h.hexdigest()


def snapshot_raw(raw_dirs: list[Path], project: Path) -> dict:
    """Build {relative_path: {size, hash}} for every file under data/raw."""
    snap = {}
    for d in raw_dirs:
        for f in d.rglob("*"):
            if f.is_file():
                key = str(f.relative_to(project))
                try:
                    size = f.stat().st_size
                except PermissionError:
                    size = -1
                snap[key] = {"size": size, "hash": file_hash(f)}
    return snap


def needs_migration(baseline: dict) -> bool:
    """Check if baseline is v1 format (has mtime_ns instead of hash)."""
    for info in baseline.values():
        if isinstance(info, dict) and "mtime_ns" in info and "hash" not in info:
            return True
        break  # only need to check one entry
    return False


def main():
    # --- Early exit: parse stdin JSON, skip if command is unrelated to data ---
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return

    command = ""
    if isinstance(data, dict):
        tool_input = data.get("tool_input", {})
        if isinstance(tool_input, dict):
            command = tool_input.get("command", "")
        elif isinstance(tool_input, str):
            command = tool_input

    command_lower = command.lower()
    if not any(kw in command_lower for kw in DATA_KEYWORDS):
        return  # fast path: nothing data-related

    # --- Locate project and data/raw directories ---
    project = Path(os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd()))

    # Target specific known locations instead of scanning entire tree
    raw_dirs = []
    root_raw = project / "data" / "raw"
    if root_raw.is_dir():
        raw_dirs.append(root_raw)
    # Also check versioned data/raw (e.g., v1/data/raw, v2/data/raw)
    for vdir in sorted(project.glob("v*/data/raw")):
        if vdir.is_dir():
            raw_dirs.append(vdir)

    if not raw_dirs:
        return  # no data/raw directory — nothing to guard

    cache = project / ".claude" / ".raw-data-snapshot.json"

    # --- Load baseline ---
    baseline = {}
    if cache.exists():
        try:
            baseline = json.loads(cache.read_text(encoding="utf-8"))
        except Exception:
            baseline = {}

    # --- Auto-migrate v1 snapshot (mtime_ns → hash) ---
    if baseline and needs_migration(baseline):
        baseline = {}  # force regeneration with new format

    current = snapshot_raw(raw_dirs, project)

    # --- First run: save baseline silently ---
    if not baseline:
        cache.parent.mkdir(parents=True, exist_ok=True)
        cache.write_text(json.dumps(current, indent=2), encoding="utf-8")
        return

    # --- Compare ---
    modified = []
    deleted = []
    for path, info in baseline.items():
        if path not in current:
            deleted.append(path)
        elif current[path]["hash"] != info.get("hash"):
            modified.append(path)

    if modified or deleted:
        print("=" * 60)
        print("=== [RAW DATA GUARD] CONSTITUTION VIOLATION ===")
        print("=" * 60)
        print("Principle 1: data/raw/ is READ-ONLY.")
        print()
        for p in deleted:
            print(f"  DELETED:  {p}")
        for p in modified:
            print(f"  MODIFIED: {p}")
        print()
        print("ACTION: STOP immediately. Restore from git/backup.")
        print("=" * 60)
        # Exit 0 — this hook is a detection layer, not enforcement.
        # Deny rules (layer 1) and attrib +R (layer 3) handle enforcement.
        sys.exit(0)

    # --- No violations: update snapshot (absorbs legitimately added new files) ---
    cache.write_text(json.dumps(current, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
