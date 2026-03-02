---
description: "Browse CSMAR databases and fetch Chinese stock market & accounting data via Python API"
user_invocable: true
---

# /fetch-csmar — CSMAR Data Access

When the user invokes `/fetch-csmar`, follow these steps:

## Step 1: Determine Mode

Ask the user which mode they need:

| Mode | Description |
|------|-------------|
| **browse** | List available databases and tables in CSMAR |
| **query** | Fetch data with column/condition filters (auto-paginated) |
| **download** | Download an entire table to CSV (for very large datasets) |
| **count** | Count rows matching a condition (before committing to a full download) |

## Step 2: Gather Parameters

Depending on mode, collect:

- **browse**: No parameters needed (lists all databases), or a database name to list its tables
- **query**: `table_name` (required), `columns` (optional — list of column names), `condition` (optional — SQL-like filter), `start_date` / `end_date` (optional), `target_dir` (default: `data/raw/`)
- **download**: `table_name` (required), `target_dir` (default: `data/raw/`)
- **count**: `table_name` (required), `condition` (optional)

## Step 3: Load Credentials and Login

Load CSMAR credentials in this priority order:
1. Environment variables: `CSMAR_ACCOUNT` and `CSMAR_PASSWORD`
2. `personal-memory.md` at project root (look for the CSMAR API Credentials section)

```python
import os

# Priority 1: Environment variables
account = os.environ.get("CSMAR_ACCOUNT")
password = os.environ.get("CSMAR_PASSWORD")

# Priority 2: personal-memory.md (parse manually if env vars not set)
if not account or not password:
    import re
    memory_path = os.path.join(os.environ.get("CLAUDE_PROJECT_DIR", "."), "personal-memory.md")
    if os.path.exists(memory_path):
        with open(memory_path, "r", encoding="utf-8") as f:
            content = f.read()
        m_account = re.search(r"\*\*Account\*\*:\s*`([^`]+)`", content)
        m_password = re.search(r"\*\*Password\*\*:\s*`([^`]+)`", content)
        if m_account:
            account = m_account.group(1)
        if m_password:
            password = m_password.group(1)

if not account or not password:
    raise RuntimeError("CSMAR credentials not found. Set CSMAR_ACCOUNT and CSMAR_PASSWORD env vars, or fill in personal-memory.md.")

from csmarapi import CsmarService

csmar = CsmarService()
csmar.login(account, password)
```

## Step 4: Execute Selected Mode

### browse mode

```python
# List all databases
databases = csmar.getListDatabaseInfo()
print(databases)

# List tables in a specific database
tables = csmar.getListTableInfo(database_name="<database>")
print(tables)

# List columns for a specific table
columns = csmar.getListColumnInfo(table_name="<table>")
print(columns)
```

### query mode (with auto-pagination)

The CSMAR API has a 200,000-row limit per request. Use `BATCH_SIZE = 190000` to stay safely under.

```python
import pandas as pd
import hashlib
from datetime import datetime

BATCH_SIZE = 190000
table_name = "<table_name>"
columns = "<col1,col2,...>"  # comma-separated, or "" for all
condition = "<condition>"     # e.g., "Stkcd = '000001'" or ""

all_data = []
page = 1

while True:
    result = csmar.query(
        tableName=table_name,
        columns=columns if columns else "",
        condition=condition if condition else "",
        limit=f"{(page-1)*BATCH_SIZE},{BATCH_SIZE}"
    )

    if result is None or len(result) == 0:
        break

    all_data.append(result)
    print(f"  Page {page}: {len(result)} rows fetched")

    if len(result) < BATCH_SIZE:
        break

    page += 1

    # Safety: warn if dataset is very large
    if page > 11:  # > 2M rows
        print("WARNING: Dataset exceeds 2M rows. Consider using 'download' mode instead.")
        break

df = pd.concat(all_data, ignore_index=True)
print(f"Total rows fetched: {len(df)}")
```

### download mode

```python
# For very large tables — uses server-side export
result = csmar.download(tableName=table_name)
# Save directly
```

### count mode

```python
count = csmar.count(
    tableName=table_name,
    condition=condition if condition else ""
)
print(f"Row count: {count}")
```

## Step 5: Save to data/raw/

Use standardized file naming: `csmar_{tablename}_{qualifier}_{YYYYMMDD}.csv`

```python
from datetime import datetime

today = datetime.now().strftime("%Y%m%d")
qualifier = condition.replace(" ", "").replace("'", "")[:30] if condition else "full"
filename = f"csmar_{table_name}_{qualifier}_{today}.csv"
target_dir = "<target_dir>"  # default: "data/raw/"

os.makedirs(target_dir, exist_ok=True)
filepath = os.path.join(target_dir, filename)

# Save with utf-8-sig for Excel compatibility with Chinese characters
df.to_csv(filepath, index=False, encoding="utf-8-sig")
print(f"Saved: {filepath}")

# Compute MD5
md5 = hashlib.md5(open(filepath, "rb").read()).hexdigest()
print(f"MD5: {md5}")
```

## Step 6: Document Provenance in REPLICATION.md

Append the data download record to REPLICATION.md:

```python
replication_path = os.path.join(os.environ.get("CLAUDE_PROJECT_DIR", "."), "REPLICATION.md")

entry = f"""
### {table_name}

- **Source**: CSMAR (国泰安)
- **Table**: `{table_name}`
- **Columns**: {columns if columns else "all"}
- **Condition**: {condition if condition else "none"}
- **Downloaded**: {datetime.now().strftime("%Y-%m-%d %H:%M")}
- **Rows**: {len(df)}
- **File**: `{filepath}`
- **MD5**: `{md5}`
"""

with open(replication_path, "a", encoding="utf-8") as f:
    f.write(entry)

print(f"Provenance appended to REPLICATION.md")
```

## Step 7: Verify and Print Summary

```python
# Verify file
df_check = pd.read_csv(filepath, encoding="utf-8-sig", nrows=5)
print(f"\nFile verification — first 5 rows:")
print(df_check.to_string())
print(f"\nShape: {df.shape}")
print(f"Columns: {list(df.columns)}")
```

Print a final summary:

```
CSMAR data fetch complete!

  Mode:      query
  Table:     <table_name>
  Columns:   <columns or "all">
  Condition: <condition or "none">
  Rows:      <N>
  Saved to:  <filepath>
  MD5:       <md5>
  Provenance: appended to REPLICATION.md
```

## Common CSMAR Tables Reference

| Table | Description |
|-------|-------------|
| `TRD_Dalyr` | Daily stock returns (日个股回报率) |
| `TRD_Mnth` | Monthly stock returns (月个股回报率) |
| `FS_Comins` | Income statement (利润表) |
| `FS_Combas` | Balance sheet (资产负债表) |
| `FS_Comscfd` | Cash flow statement (现金流量表) |
| `CG_Board` | Board of directors (董事会) |
| `TRD_Index` | Market index returns (市场指数回报) |
| `STK_MKT_Dalyr` | Daily market trading data (日市场交易数据) |
| `CG_Ycomp` | Executive compensation (高管薪酬) |
| `CG_ShareHolder` | Shareholder structure (股权结构) |

## Troubleshooting

- **Login fails**: Check credentials in env vars or `personal-memory.md`. CSMAR accounts may expire.
- **Empty results**: Verify table name and column names using `browse` mode first.
- **Timeout**: Large queries may time out. Use `count` mode first, then paginate or switch to `download` mode.
- **Encoding issues**: Always use `utf-8-sig` when saving CSV files with Chinese characters.
