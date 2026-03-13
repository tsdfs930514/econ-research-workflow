---
name: compile-latex
description: "Compile LaTeX paper with pdflatex and bibtex pipeline -- error checking, missing references, undefined citations, compilation log analysis, PDF generation. Use when: 'compile LaTeX', 'compile paper', 'pdflatex', 'bibtex', 'build PDF', 'LaTeX errors', 'compile tex'."
user_invocable: true
---

# /compile-latex — LaTeX Compilation Pipeline

When the user invokes `/compile-latex`, compile a .tex file through the full pdflatex + bibtex pipeline.

## Step 1: Determine Target

- If user specifies a file: use that (e.g., `/compile-latex v1/paper/main_en.tex`)
- If not specified: look for `.tex` files in the current version's `paper/` directory
  - If multiple found, ask which one to compile
  - Common targets: `main_cn.tex`, `main_en.tex`

## Step 2: Compile

**Always run the full 4-pass compilation.** Skipping any pass produces broken output:

| Pass | Purpose | What breaks if skipped |
|------|---------|----------------------|
| 1. `pdflatex` | Initial compilation, writes `.aux` with `\citation` and `\label` info | No PDF at all |
| 2. `bibtex` | Reads `.aux`, resolves `\cite{}` from `.bib` files, writes `.bbl` | All `\cite{}` show "?" |
| 3. `pdflatex` | Incorporates `.bbl` bibliography, updates cross-references | Citations still "?", some `\ref{}` still "??" |
| 4. `pdflatex` | Resolves forward references and page numbers | Some `\ref{}` and page numbers wrong |

```bash
cd /path/to/paper/directory
pdflatex -interaction=nonstopmode main.tex
bibtex main
pdflatex -interaction=nonstopmode main.tex
pdflatex -interaction=nonstopmode main.tex
```

Use `-interaction=nonstopmode` so compilation continues past errors (allowing us to collect all issues).

**Never run pdflatex only once.** Even if there are no citations, the second and third passes are needed to resolve `\ref{}`, `\pageref{}`, table/figure numbering, and table of contents entries. If bibtex reports "I found no \citation commands", the remaining pdflatex passes must still be run.

## Step 3: Check for Errors

Read the `.log` file produced by pdflatex and check for:

### Errors (must fix)
- `! LaTeX Error:` — package errors, undefined commands
- `! Missing` — missing delimiters
- `! Undefined control sequence` — typos in commands
- `! File not found` — missing input files or figures

### Warnings (should fix)
- `LaTeX Warning: Reference .* undefined` — broken `\ref{}` or `\cite{}`
- `LaTeX Warning: Label .* multiply defined` — duplicate labels
- `Overfull \\hbox` — lines extending past margins (report if > 10pt overfull)
- `Package natbib Warning: Citation .* undefined` — missing bibliography entries

### Info (report if relevant)
- Number of pages in output PDF
- Whether bibliography was successfully built
- Total number of warnings

## Step 4: Report Results

```
Compilation Report for main_en.tex
═══════════════════════════════════

  Status:     SUCCESS (with warnings)
  Output:     v1/paper/main_en.pdf
  Pages:      24

  Errors:     0
  Warnings:   3
    - Undefined reference: fig:event_study (line 142)
    - Overfull hbox (12.3pt) at line 256
    - Citation "smith2024" undefined

  Action needed:
    1. Add label for fig:event_study in your figures section
    2. Check line 256 for long text that needs rewording
    3. Add smith2024 entry to references.bib
```

## Step 5: Handle Missing Packages

If compilation fails with `! LaTeX Error: File 'package.sty' not found`:

- On TeX Live: suggest `tlmgr install <package>`
- On MiKTeX: suggest opening MiKTeX Console to install missing packages
- Report the specific package name clearly

## Notes

- For Chinese papers (`main_cn.tex`), `xelatex` may be needed instead of `pdflatex` if using `ctex` with system fonts. Check the documentclass and suggest `xelatex` if appropriate.
- If `bibtex` reports "I found no \citation commands", the bibliography section may be commented out — this is normal for early drafts.
