# LaTeX Paper Templates

Templates for `/init-project` — Step 10. Four journal formats supported.

## Table of Contents

- [Chinese Journal Template (main_cn.tex)](#chinese-journal-template)
- [English TOP5 Template (main_en.tex)](#english-top5-template)
- [NBER Working Paper Template (main_nber.tex)](#nber-working-paper-template)
- [SSRN Preprint Template (main_ssrn.tex)](#ssrn-preprint-template)

---

## Chinese Journal Template

Create `<project-name>/v1/paper/main_cn.tex` (if CN or both):

```latex
\documentclass[12pt,a4paper]{article}
\usepackage[UTF8]{ctex}
\usepackage{booktabs,multirow,threeparttable}
\usepackage{graphicx}
\usepackage{amsmath,amssymb}
\usepackage[margin=2.5cm]{geometry}
\usepackage{setspace}
\usepackage{natbib}

\title{<项目标题>}
\author{<研究者姓名>\\<机构名称>}
\date{\today}

\begin{document}
\maketitle

\begin{abstract}
% 摘要内容
\end{abstract}

\textbf{关键词：}

% \input{sections/01_introduction}
% \input{sections/02_literature}
% \input{sections/03_background}
% \input{sections/04_data}
% \input{sections/05_strategy}
% \input{sections/06_results}
% \input{sections/07_robustness}
% \input{sections/08_conclusion}

\bibliographystyle{apalike}
\bibliography{bib/references}

\end{document}
```

---

## English TOP5 Template

Create `<project-name>/v1/paper/main_en.tex` (if EN or both):

```latex
\documentclass[12pt,a4paper]{article}
\usepackage{booktabs,multirow,threeparttable}
\usepackage{graphicx}
\usepackage{amsmath,amssymb}
\usepackage[margin=1in]{geometry}
\usepackage{setspace}\doublespacing
\usepackage{natbib}

\title{<Project Title>}
\author{<Researcher Name>\\<Institution>}
\date{\today}

\begin{document}
\maketitle

\begin{abstract}
% Abstract content
\end{abstract}

\textbf{Keywords:}

\newpage

% \input{sections/01_introduction}
% \input{sections/02_literature}
% \input{sections/03_background}
% \input{sections/04_data}
% \input{sections/05_strategy}
% \input{sections/06_results}
% \input{sections/07_robustness}
% \input{sections/08_conclusion}

\bibliographystyle{aer}
\bibliography{bib/references}

\end{document}
```

---

## NBER Working Paper Template

Create `<project-name>/v1/paper/main_nber.tex` (if format is `NBER` or `all`):

```latex
\documentclass[12pt,a4paper]{article}
\usepackage{booktabs,multirow,threeparttable}
\usepackage{graphicx}
\usepackage{amsmath,amssymb}
\usepackage[margin=1in]{geometry}
\usepackage{setspace}\onehalfspacing
\usepackage[round]{natbib}
\usepackage{hyperref}
\usepackage{caption}

% --- NBER Working Paper Formatting ---
\title{<Project Title>\thanks{We thank [acknowledgments: seminar participants, discussants, funding agencies]. Author1: [affiliation], [email]. Author2: [affiliation], [email].}}
\author{<Author 1>\\ \textit{<Institution 1>} \and <Author 2>\\ \textit{<Institution 2>}}
\date{This draft: \today}

\begin{document}
\maketitle

\begin{abstract}
\noindent
% Abstract: 100-200 words. Summarize research question, method, and key findings.
\end{abstract}

\medskip

\noindent\textbf{JEL Classification:} <J31, C21, H53>

\noindent\textbf{Keywords:} <keyword1, keyword2, keyword3>

\bigskip
\noindent\rule{\textwidth}{0.4pt}

\newpage

% \input{sections/01_introduction}
% \input{sections/02_literature}
% \input{sections/03_background}
% \input{sections/04_data}
% \input{sections/05_strategy}
% \input{sections/06_results}
% \input{sections/07_robustness}
% \input{sections/08_conclusion}

\newpage
\bibliographystyle{aer}
\bibliography{bib/references}

% \newpage
% \appendix
% \input{sections/appendix_a_data}
% \input{sections/appendix_b_robustness}

\end{document}
```

---

## SSRN Preprint Template

Create `<project-name>/v1/paper/main_ssrn.tex` (if format is `SSRN` or `all`):

```latex
\documentclass[12pt,a4paper]{article}
\usepackage{booktabs,multirow,threeparttable}
\usepackage{graphicx}
\usepackage{amsmath,amssymb}
\usepackage[margin=1in]{geometry}
\usepackage{setspace}\singlespacing
\usepackage[round]{natbib}
\usepackage{hyperref}
\usepackage{caption}
\usepackage{fancyhdr}

% --- SSRN Preprint Formatting ---
\pagestyle{fancy}
\fancyhf{}
\rhead{\thepage}
\lfoot{\footnotesize Draft --- comments welcome}
\rfoot{\footnotesize Available at SSRN: \url{https://ssrn.com/abstract=XXXXXXX}}
\renewcommand{\headrulewidth}{0pt}
\renewcommand{\footrulewidth}{0.4pt}

\title{<Project Title>}
\author{
  <Author 1>\\
  \textit{<Institution 1>}\\
  \href{mailto:author1@example.com}{author1@example.com}
  \and
  <Author 2>\\
  \textit{<Institution 2>}\\
  \href{mailto:author2@example.com}{author2@example.com}
}
\date{
  This version: \today\\
  First version: <Month Year>
}

\begin{document}
\maketitle
\thispagestyle{empty}

\begin{abstract}
\noindent
% Abstract: 150-250 words. Make it self-contained — many SSRN readers only see the abstract.
% Clearly state: (1) research question, (2) method, (3) data, (4) key finding, (5) contribution.
\end{abstract}

\medskip

\noindent\textbf{Keywords:} <keyword1, keyword2, keyword3, keyword4>

\noindent\textbf{JEL Classification:} <J31, C21, H53>

\newpage
\setcounter{page}{1}

% \input{sections/01_introduction}
% \input{sections/02_literature}
% \input{sections/03_background}
% \input{sections/04_data}
% \input{sections/05_strategy}
% \input{sections/06_results}
% \input{sections/07_robustness}
% \input{sections/08_conclusion}

\newpage
\bibliographystyle{aer}
\bibliography{bib/references}

% \newpage
% \appendix
% \input{sections/appendix_a_data}
% \input{sections/appendix_b_robustness}

\end{document}
```
