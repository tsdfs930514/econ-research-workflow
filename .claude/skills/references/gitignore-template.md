# Gitignore Template

Template for `/init-project` — Step 9. Create `<project-name>/.gitignore`:

```
# Data files (may be large or restricted)
*.dta
*.csv
*.xlsx
*.sas7bdat
*.rds

# Raw data (project-level, shared across versions)
data/raw/*
!data/raw/.gitkeep

# Version-specific temp
*/data/temp/*
!*/data/temp/.gitkeep

# Stata logs and temporary files
*.log
*.smcl
*.gph

# Python
__pycache__/
*.pyc
.ipynb_checkpoints/

# OS files
.DS_Store
Thumbs.db

# LaTeX auxiliary files
*.aux
*.bbl
*.blg
*.fdb_latexmk
*.fls
*.synctex.gz
*.out
*.toc
```
