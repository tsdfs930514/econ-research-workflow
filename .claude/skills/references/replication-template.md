# REPLICATION.md Template

Template for `/init-project` — Step 6. Create `<project-name>/v1/REPLICATION.md` following AEA Data Editor standards:

```markdown
# Replication Package

## Overview

This replication package contains all code and data necessary to reproduce the
results in "<Paper Title>" by <Author(s)>.

**Data Availability Statement**: [Describe data sources and access conditions]

## Data Sources

| Data | Source | Access | Files |
|------|--------|--------|-------|
| [Dataset 1] | [Provider] | [Public/Restricted] | `data/raw/[filename]` |
| [Dataset 2] | [Provider] | [Public/Restricted] | `data/raw/[filename]` |

## Computational Requirements

### Software
- Stata 18/MP (required for all .do files)
- Python 3.10+ with packages: pyfixest, pandas, numpy

### Stata Packages
[List all required Stata packages with version numbers]

### Hardware
- Approximate runtime: [X minutes/hours] on [machine description]
- Memory requirements: [X GB RAM]

## Instructions

1. Set the root directory in `code/stata/master.do`
2. Install required Stata packages (see `master.do` header)
3. Run `master.do` to execute all analyses in sequence
4. Output tables appear in `output/tables/`
5. Output figures appear in `output/figures/`

## File Structure

```
data/
└── raw/                        # Original data (READ-ONLY, shared across versions)

v1/
├── code/
│   ├── stata/
│   │   ├── master.do           # Master script (run this)
│   │   ├── 01_clean_data.do    # Data preparation
│   │   ├── 02_desc_stats.do    # Descriptive statistics
│   │   ├── 03_main_regression.do # Main results
│   │   ├── 04_robustness.do    # Robustness checks
│   │   └── ...
│   └── python/
│       └── cross_validation.py # Cross-validates Stata results
├── data/
│   ├── clean/                  # Processed data
│   └── temp/                   # Intermediate files
├── output/
│   ├── tables/                 # LaTeX tables
│   ├── figures/                # PDF figures
│   └── logs/                   # Execution logs
└── REPLICATION.md              # This file
```

## Output-to-Table Mapping

| Table/Figure | Script | Output File |
|-------------|--------|-------------|
| Table 1     | `02_desc_stats.do` | `output/tables/tab_descriptive.tex` |
| Table 2     | `03_main_regression.do` | `output/tables/tab_main_results.tex` |
| Figure 1    | `06_figures.do` | `output/figures/fig_event_study.pdf` |
| ...         | ...    | ... |

## Data Provenance

For each raw data file, document:
- **Source**: Where was it obtained?
- **Date accessed**: When was it downloaded?
- **DOI/URL**: Persistent identifier
- **License**: Usage restrictions
- **Checksum**: MD5 or SHA256 hash of the file

| File | Source | Date | DOI/URL | MD5 |
|------|--------|------|---------|-----|
| [file.dta] | [source] | [date] | [doi] | [hash] |
```
