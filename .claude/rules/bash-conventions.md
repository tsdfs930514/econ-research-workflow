# Bash Command Conventions

## No Chained Commands

**NEVER** use `&&`, `||`, or `;` to chain multiple commands in a single Bash call.

### Why

1. **Permission bypass**: Chained commands are matched as a single string. `Bash(python *)` won't match `cd /path && python script.py` because it starts with `cd`. This defeats the entire permission system.
2. **Error visibility**: When commands are chained, intermediate failures can be swallowed. Separate calls give clear per-command exit codes.
3. **Hook accuracy**: PostToolUse hooks (e.g., `stata-log-check.py`, `raw-data-guard.py`) run once per tool call. Chaining hides which command triggered an issue.

### Prohibited Patterns

```bash
# BAD — chained with &&
cd /path && python script.py

# BAD — chained with ||
ls dir/ 2>/dev/null || echo "missing"

# BAD — chained with ;
mkdir -p output; python run.py

# BAD — subshell tricks
(cd data && rm *.csv)
```

### Required Pattern

Use **separate Bash tool calls** for each independent command:

```bash
# Call 1
cd /path

# Call 2
python script.py
```

If you need to check a condition (e.g., directory existence), use a single command that does the check directly:

```bash
# GOOD — single command, no chain
ls dir/

# GOOD — test with built-in
test -d dir/ && echo exists   # EXCEPTION: simple test-then-echo is allowed
```

### Narrow Exception

A `&&` chain is allowed ONLY when:
- The first command is `cd` and the second is the actual work command, AND
- The operation **requires** being run from that directory (e.g., `cd project && make`)

Even then, prefer using absolute paths to avoid `cd` entirely.

## Absolute Paths Preferred

Use absolute paths instead of `cd`-then-run:

```bash
# GOOD
python "F:/Learning/project/v1/code/python/01_clean.py"

# BAD
cd "F:/Learning/project/v1/code/python" && python 01_clean.py
```

## Stderr Redirection

Do NOT suppress stderr with `2>/dev/null`. Errors should be visible:

```bash
# BAD
ls output/ 2>/dev/null

# GOOD
ls output/
```
