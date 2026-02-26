"""
01_convert_csv.py
=================
jvae023 - "Effectiveness of Environmental Provisions in RTAs"
Abman, Lundberg & Ruta

Reads the 3 CSV source files from the replication package and converts
them to Stata .dta format for downstream LASSO analysis.

Source:  F:/Learning/replication pakage/jvae023_extracted/Replication Files/
Target:  F:/Learning/econ-research-workflow/tests/replication-jvae023-lasso/v1/data/raw/
"""

import os
import sys
import pandas as pd

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
SRC_DIR = r"F:\Learning\replication pakage\jvae023_extracted\Replication Files"
DST_DIR = r"F:\Learning\econ-research-workflow\tests\replication-jvae023-lasso\v1\data\raw"

CSV_FILES = [
    "country_panel.csv",
    "rta_data.csv",
    "rta_panel_full.csv",
]

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def clean_colnames(df: pd.DataFrame) -> pd.DataFrame:
    """
    Stata variable names must be <= 32 chars, start with a letter or _,
    and contain only letters, digits, and underscores.  Periods and other
    punctuation in the R-exported CSV headers are replaced here.
    """
    new_cols = []
    for c in df.columns:
        c_clean = c.strip().replace(".", "_").replace(" ", "_").replace("-", "_")
        # Remove any remaining non-alphanumeric / non-underscore chars
        c_clean = "".join(ch for ch in c_clean if ch.isalnum() or ch == "_")
        # Ensure it starts with a letter or underscore
        if c_clean and c_clean[0].isdigit():
            c_clean = "_" + c_clean
        # Truncate to 32 characters (Stata limit)
        c_clean = c_clean[:32]
        new_cols.append(c_clean)
    df.columns = new_cols
    return df


def convert_one(filename: str) -> None:
    """Read a single CSV, print diagnostics, write .dta."""
    src_path = os.path.join(SRC_DIR, filename)
    stem = os.path.splitext(filename)[0]
    dst_path = os.path.join(DST_DIR, f"{stem}.dta")

    print("=" * 72)
    print(f"  FILE: {filename}")
    print("=" * 72)

    if not os.path.isfile(src_path):
        print(f"  *** WARNING: source file not found: {src_path}")
        return

    # Read CSV -  low_memory=False to let pandas infer dtypes fully
    df = pd.read_csv(src_path, low_memory=False)

    # Clean column names for Stata compatibility
    df = clean_colnames(df)

    # --- Dimensions --------------------------------------------------------
    nrows, ncols = df.shape
    print(f"  Dimensions : {nrows:,} rows x {ncols} columns")
    print()

    # --- Variable names & types --------------------------------------------
    print(f"  {'Variable':<35s} {'Dtype':<15s} {'Non-null':>10s}  {'Example'}")
    print(f"  {'-'*35} {'-'*15} {'-'*10}  {'-'*30}")
    for col in df.columns:
        dtype_str = str(df[col].dtype)
        non_null = f"{df[col].notna().sum()}"
        # Show first non-null value as an example
        first_val = df[col].dropna().iloc[0] if df[col].notna().any() else "NA"
        # Truncate long example values
        first_str = str(first_val)
        if len(first_str) > 30:
            first_str = first_str[:27] + "..."
        print(f"  {col:<35s} {dtype_str:<15s} {non_null:>10s}  {first_str}")
    print()

    # --- Downcast wide-integer columns to avoid Stata overflow -------------
    # Stata .dta (version 117/118) supports int8/16/32 and float/double.
    # pandas to_stata will handle most of this, but very large int64 values
    # can cause issues.  Convert int64 cols to float64 as a safe fallback.
    for col in df.select_dtypes(include=["int64"]).columns:
        df[col] = df[col].astype("float64")

    # --- Write .dta --------------------------------------------------------
    try:
        df.to_stata(dst_path, write_index=False, version=118)
        size_mb = os.path.getsize(dst_path) / (1024 * 1024)
        print(f"  Saved: {dst_path}")
        print(f"  Size : {size_mb:.2f} MB")
    except Exception as exc:
        print(f"  *** ERROR writing {dst_path}: {exc}")
        # Fallback: try version 117 (older Stata format, wider compat)
        try:
            df.to_stata(dst_path, write_index=False, version=117)
            size_mb = os.path.getsize(dst_path) / (1024 * 1024)
            print(f"  Saved (v117 fallback): {dst_path}")
            print(f"  Size : {size_mb:.2f} MB")
        except Exception as exc2:
            print(f"  *** FATAL: version 117 also failed: {exc2}")

    print()


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    print()
    print("jvae023 CSV-to-DTA Converter")
    print("RTAs & Environment -- Abman, Lundberg & Ruta")
    print()

    # Verify source directory
    if not os.path.isdir(SRC_DIR):
        print(f"ERROR: Source directory not found:\n  {SRC_DIR}")
        sys.exit(1)

    # Ensure destination directory exists
    os.makedirs(DST_DIR, exist_ok=True)

    # Convert each file
    for fname in CSV_FILES:
        convert_one(fname)

    # Summary
    print("=" * 72)
    print("  CONVERSION COMPLETE")
    print(f"  Output directory: {DST_DIR}")
    dta_files = [f for f in os.listdir(DST_DIR) if f.endswith(".dta")]
    print(f"  DTA files created: {len(dta_files)}")
    for f in sorted(dta_files):
        fpath = os.path.join(DST_DIR, f)
        sz = os.path.getsize(fpath) / (1024 * 1024)
        print(f"    {f:<30s}  {sz:.2f} MB")
    print("=" * 72)


if __name__ == "__main__":
    main()
