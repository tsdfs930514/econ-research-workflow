# 经济学研究工作流

基于 Claude Code 的可复制经济学研究模板，集成自动化 Stata/Python 管线、对抗式质量保证和交叉验证基础设施。

灵感来源：[pedrohcgs/claude-code-my-workflow](https://github.com/pedrohcgs/claude-code-my-workflow)。

---

## 功能特性

- **36 个技能** — 覆盖完整研究生命周期的斜杠命令工作流（数据清洗、DID/IV/RDD/面板/SDID/自举/安慰剂/Logit-Probit/LASSO 估计、交叉验证、表格、论文写作、翻译、润色、去 AI 化改写、逻辑检查、审稿、管线编排、综合报告、CSMAR 数据获取、探索沙盒、会话连续性、苏格拉底式研究工具和自扩展）
- **9 个智能体** — 3 个独立智能体（paper-reviewer、robustness-checker、cross-checker）加 3 对对抗式 critic-fixer（代码、计量、表格），强制关注点分离
- **8 条规则** — 4 条路径作用域的编码/计量规范 + 4 条始终生效规则（宪法、编排协议、Stata 错误验证、bash 约定）
- **4 个生命周期钩子** — 自动会话上下文加载、压缩前记忆保存、Stata 运行后错误检测、原始数据完整性守护
- **对抗式质量保证循环** — `/adversarial-review` 运行 critic → fixer → re-critic 循环（最多 5 轮），直到质量评分 >= 95
- **可执行质量评分器** — `quality_scorer.py` 在 6 个维度（满分 100）上评分，包括从 .do 文件自动检测的方法特定诊断
- **探索沙盒** — `/explore` 用于宽松阈值的假设检验；`/promote` 将结果提升至主管线
- **Stata + Python/R 交叉验证** — 每个回归都通过 `pyfixest` 和 R `fixest` 跨语言验证
- **多格式输出** — 中文期刊（经济研究/管理世界）、英文 TOP5（AER/QJE）、NBER 工作论文、SSRN 预印本
- **版本控制分析** — `v1/`、`v2/`、... 目录结构，含完整复制包
- **会话连续性** — `/session-log` 用于显式会话管理，集成 MEMORY.md

---

## 工作原理

本仓库是一个**项目级模板**。`.claude/` 目录包含所有技能、智能体和规则 — 在项目目录中运行 `claude` 时自动加载，无需全局安装。

两种使用方式：

- **作为完整项目模板** — Fork 本仓库来启动包含完整工作流的新研究项目
- **按需选取技能** — 将特定的 `.claude/skills/*.md` 文件复制到你自己项目的 `.claude/skills/` 目录

## 快速开始

### 1. Fork 并克隆

```bash
# 在 GitHub 上 Fork 本仓库，然后：
git clone https://github.com/<your-username>/econ-research-workflow.git
cd econ-research-workflow
```

### 2. 安装前置依赖

| 软件 | 版本 | 用途 |
|------|------|------|
| **Stata** | 18（推荐 MP 版） | 所有计量经济学估计 |
| **Python** | 3.10+ | 交叉验证（`pyfixest`、`pandas`、`numpy`） |
| **Claude Code** | 最新版 | CLI 工具 — 从 [claude.com/claude-code](https://claude.com/claude-code) 安装 |
| **Git Bash**（Windows） | — | Stata 执行的 Shell 环境 |
| **LaTeX** | 可选 | `/compile-latex` 论文编译（pdflatex + bibtex） |

```bash
pip install pyfixest pandas numpy polars matplotlib stargazer
```

### 3. 配置

打开 `CLAUDE.md` 填写 `[PLACEHOLDER]` 字段：
- `[PROJECT_NAME]` — 你的研究项目名称
- `[INSTITUTION_NAME]` — 你的机构
- `[RESEARCHER_NAMES]` — 研究者姓名
- `[DATE]` — 创建日期
- 更新 Stata 可执行文件路径以匹配本地安装

### 4. 启动 Claude Code 开始工作

```bash
# 在项目目录中启动 Claude Code
claude

# 初始化新研究项目（创建 v1/ 目录结构）
/init-project
```

将原始数据放入 `data/raw/`，然后运行分析：

```bash
/data-describe → /run-did（或 /run-iv、/run-rdd、/run-panel）
    → /cross-check → /make-table → /adversarial-review → /score
```

---

## 技能参考

| 技能 | 触发场景 | 功能描述 |
|------|----------|----------|
| `/init-project` | 启动新项目 | 初始化标准化目录结构，含 master.do、REPLICATION.md、模板 |
| `/data-describe` | 探索数据 | 生成描述性统计和变量分布（Stata + Python） |
| `/run-did` | DID 分析 | 完整 DID/TWFE/Callaway-Sant'Anna 管线（含诊断检验） |
| `/run-iv` | IV 分析 | 完整 IV/2SLS 管线（含一阶段、弱工具变量检验、LIML 比较） |
| `/run-rdd` | RDD 分析 | 完整 RDD 管线（含带宽敏感性、密度检验、安慰剂断点） |
| `/run-panel` | 面板分析 | 面板 FE/RE/GMM 管线（含 Hausman、序列相关、CD 检验） |
| `/cross-check` | 验证结果 | Stata 与 Python/R 回归结果交叉验证（目标：系数差异 < 0.1%） |
| `/robustness` | 稳健性检验 | 基线回归的稳健性检验套件 — 替代设定、子样本、聚类、Oster 界、wild bootstrap |
| `/make-table` | 格式化表格 | 生成出版级 LaTeX 回归表格（AER 或三线表格式） |
| `/write-section` | 撰写论文 | 按中文或英文期刊规范撰写论文章节 |
| `/review-paper` | 模拟审稿 | 三位模拟同行评审（含结构化反馈）；可选 APE 式多轮深度评审 |
| `/lit-review` | 文献综述 | 结构化文献综述（含 BibTeX 条目） |
| `/adversarial-review` | 质量保证 | 跨代码、计量、表格领域的对抗式 critic-fixer 循环 |
| `/score` | 质量评分 | 运行可执行质量评分器（6 个维度，100 分制） |
| `/commit` | Git 提交 | 智能提交（类型前缀、数据安全警告、自动生成消息） |
| `/compile-latex` | 编译论文 | 运行 pdflatex/bibtex 管线（含错误检查） |
| `/context-status` | 会话上下文 | 显示当前版本、近期决策、质量评分、git 状态 |
| `/run-sdid` | SDID 分析 | 合成 DID 分析（含单位/时间权重和推断） |
| `/run-bootstrap` | 自举推断 | 配对、wild cluster、残差和 teffects 自举管线 |
| `/run-placebo` | 安慰剂检验 | 时间、结果、工具变量和置换安慰剂检验管线 |
| `/run-logit-probit` | Logit/Probit 分析 | Logit/Probit、倾向得分、处理效应（RA/IPW/AIPW）、条件 Logit |
| `/run-lasso` | LASSO/正则化 | LASSO、双重选择后推断、严格 LASSO、R `glmnet` 匹配管线 |
| `/explore` | 探索沙盒 | 建立 `explore/` 目录（宽松质量阈值 >= 60），用于快速假设检验 |
| `/promote` | 提升结果 | 将探索性文件从 `explore/` 提升至主 `vN/` 管线（含重编号和质量检查） |
| `/session-log` | 会话连续性 | 会话启动/结束管理（MEMORY.md 上下文加载和记录） |
| `/interview-me` | 研究构思 | 双语苏格拉底式访谈，将研究想法形式化为结构化提案 |
| `/devils-advocate` | 策略挑战 | 分析前识别策略威胁评估（威胁、替代方案、伪证检验） |
| `/learn` | 自扩展 | 在会话中创建新规则或技能（受宪法守护） |
| `/run-pipeline` | 编排管线 | 从研究计划自动检测方法并端到端运行完整技能序列 |
| `/synthesis-report` | 生成报告 | 汇总所有输出为结构化综合报告（Markdown + LaTeX） |
| `/translate` | 翻译论文 | 中英文学术论文翻译（含期刊特定规范） |
| `/polish` | 润色论文 | 中/英文润色、精炼、压缩和扩展（5 种子模式） |
| `/de-ai` | 去 AI 化 | 检测并去除 AI 生成的写作模式，产出自然学术文体 |
| `/fetch-csmar` | CSMAR 数据 | 浏览 CSMAR 数据库，通过 Python API 获取中国股市和会计数据 |
| `/logic-check` | 逻辑检查 | 终审红线检查 — 仅捕捉关键错误，不涉及风格偏好 |

---

## 智能体参考

| 智能体 | 角色 | 工具权限 |
|--------|------|----------|
| `paper-reviewer` | 模拟同行评审的全文审稿 | Read, Grep, Glob |
| `robustness-checker` | 缺失的稳健性检验和敏感性分析 | Read, Grep, Glob |
| `cross-checker` | Stata 与 Python 交叉验证 | Read, Grep, Glob, Bash |
| `code-critic` | 对抗式代码审查（规范、安全、防御性编程） | 只读 |
| `code-fixer` | 实施 code-critic 发现的修复 | 完全权限 |
| `econometrics-critic` | 对抗式计量审查（诊断检验、识别策略、稳健性） | 只读 |
| `econometrics-fixer` | 实施 econometrics-critic 发现的修复 | 完全权限 |
| `tables-critic` | 对抗式表格审查（格式、显著性星号、报告完整性） | 只读 |
| `tables-fixer` | 实施 tables-critic 发现的修复 | 完全权限 |

---

## 典型工作流序列

### 完整论文管线

```
/init-project → /data-describe → /run-did → /cross-check → /robustness
    → /make-table → /write-section → /review-paper → /adversarial-review
    → /score → /synthesis-report → /compile-latex → /commit
```

### 自动化管线（单条命令）

```
/run-pipeline  →  自动检测方法  →  运行完整序列  →  /synthesis-report
```

### 快速检查（单个回归）

```
/run-{method} → /cross-check → /score
```

支持的方法：`did`、`iv`、`rdd`、`panel`、`sdid`、`bootstrap`、`placebo`、`logit-probit`、`lasso`

### 研究构思

```
/interview-me → /devils-advocate → /data-describe → /run-{method}
```

### 论文写作与编辑

```
/write-section → /polish → /de-ai → /logic-check → /compile-latex
```

翻译：`/translate`（中→英或英→中，含期刊特定规范）

### 修改回复

```
/context-status → （处理审稿意见）→ /adversarial-review → /score → /commit
```

---

## 目录结构

```
econ-research-workflow/
├── .claude/
│   ├── agents/           # 9 个专业智能体
│   ├── hooks/            # 生命周期钩子脚本（会话加载器、Stata 日志检查）
│   ├── scripts/          # 自动批准的封装脚本（run-stata.sh）
│   ├── rules/            # 编码规范、计量标准（4 条路径作用域 + 4 条始终生效，含宪法）
│   ├── settings.json     # 钩子 + 权限配置
│   └── skills/           # 36 个斜杠命令技能 + references/
├── scripts/
│   └── quality_scorer.py # 可执行 6 维度质量评分器
├── tests/                # 测试用例（DID、RDD、IV、面板、完整管线）
├── CLAUDE.md             # 项目配置（填写占位符）
├── MEMORY.md             # 跨会话学习和决策日志
├── ROADMAP.md            # Phase 1-7 实施历史
└── README.md             # 英文说明
```

每个通过 `/init-project` 创建的研究项目遵循：

```
project-name/
├── data/
│   └── raw/              # 原始数据（只读，跨版本共享）
└── v1/
    ├── code/stata/       # .do 文件（编号：01_、02_、...）
    ├── code/python/      # 用于交叉验证的 .py 文件
    ├── data/clean/       # 清洗后数据
    ├── data/temp/        # 中间文件
    ├── output/tables/    # LaTeX 表格（.tex）
    ├── output/figures/   # 图表（.pdf/.png）
    ├── output/logs/      # Stata .log 文件
    ├── paper/sections/   # LaTeX 章节文件
    ├── paper/bib/        # BibTeX 文件
    ├── _VERSION_INFO.md  # 版本元数据
    └── REPLICATION.md    # AEA 数据编辑器格式复制指南
```

---

## 测试套件

5 个端到端测试，覆盖所有主要估计方法：

| 测试 | 方法 | 状态 |
|------|------|------|
| `test1-did` | DID / TWFE / Callaway-Sant'Anna | 通过 |
| `test2-rdd` | RDD / rdrobust / 密度检验 | 通过 |
| `test3-iv` | IV / 2SLS / 一阶段诊断 | 通过 |
| `test4-panel` | 面板 FE / RE / GMM | 通过 |
| `test5-full-pipeline` | 端到端多脚本管线 | 通过 |

测试中发现的问题记录在 `tests/ISSUES_LOG.md` 中，并在 `MEMORY.md` 中跟踪。

---

## 治理机制

工作流在**宪法**（`.claude/rules/constitution.md`）下运行，定义了 5 条不可变原则：原始数据完整性、完全可复制性、强制交叉验证、版本保留和评分诚信。所有技能、智能体和规则都在此框架内运行。`/learn` 技能不能创建违反宪法的规则。

非琐碎任务遵循**先规格后计划**协议（编排器中的 Phase 0），要求在实施前先确定 MUST/SHOULD/MAY 需求。

## 路线图

详见 [ROADMAP.md](ROADMAP.md) 了解完整的 Phase 1-7 实施历史。

### 钩子

`.claude/settings.json` 中配置了 4 个生命周期钩子：

| 钩子 | 触发器 | 功能 |
|------|--------|------|
| 会话启动加载器 | `SessionStart` | 读取 MEMORY.md，显示近期条目和最后质量评分 |
| 压缩前保存 | `PreCompact` | 在上下文压缩前提示将会话摘要写入 MEMORY.md |
| Stata 日志检查 | `PostToolUse` (Bash) | Stata 运行后自动解析 `.log` 文件中的 `r(xxx)` 错误 |
| 原始数据守护 | `PostToolUse` (Bash) | 比较 `data/raw/` 文件快照以检测未授权修改 |

### 始终生效规则

4 条始终生效规则（无路径作用域，每个会话加载）：

| 规则 | 用途 |
|------|------|
| `constitution.md` | 5 条不可变原则（原始数据完整性、可复制性、交叉验证、版本保留、评分诚信） |
| `orchestrator-protocol.md` | 规格-计划-实施-验证-审查-修复-评分循环，含"直接做"模式 |
| `stata-error-verification.md` | 强制在重新运行 Stata 前读取钩子输出；防止日志覆盖误报 |
| `bash-conventions.md` | 禁止链式命令（`&&`、`||`、`;`）；使用独立工具调用和绝对路径 |

### 权限与安全

权限系统使用**全允许 + 拒绝名单**模型：

- **拒绝**（通过 `settings.json` 共享）：35 条规则，分 3 类 — 原始数据保护（宪法原则 1）、破坏性操作（`rm -rf`、`git push --force`、`git reset --hard`）、凭证/基础设施保护（`.env`、`.credentials`、`.claude/hooks/**`、`.claude/scripts/**`、`.claude/settings.json`）。
- **允许**（通过 `settings.local.json` 个人配置，已 gitignore）：默认 Fork 仓库的每个操作都会提示。免提示：`cp .claude/settings.local.json.example .claude/settings.local.json`。

纵深防御：

| 层 | 机制 | 范围 |
|----|------|------|
| 1 | settings.json 中的 `deny` 规则 | 工具级字符串匹配（防止常见失误） |
| 2 | `raw-data-guard.py` PostToolUse 钩子 | Bash 后检测 `data/raw/` 变更（捕捉 Python/R 脚本绕过） |
| 3 | 操作系统级 `attrib +R` 于 `data/raw/` | 文件系统强制只读（每个项目手动设置） |
| 4 | 宪法 + 行为规则 | Claude 自觉遵守约束 |

---

## 更新日志

| 日期 | 版本 | 描述 |
|------|------|------|
| 2026-02-25 | v0.1 | 初始提交 — 14 个技能、6 个智能体、CLAUDE.md 模板、目录约定 |
| 2026-02-25 | v0.2 | Phase 1 — 对抗式 QA 循环（`/adversarial-review`）、质量评分器（`quality_scorer.py`）、6 个新技能 |
| 2026-02-25 | v0.3 | Phase 2 — 3 个生命周期钩子、路径作用域规则、探索沙盒（`/explore` + `/promote`）、会话连续性 |
| 2026-02-25 | v0.4 | NBER 工作论文和 SSRN 预印本 LaTeX 样式支持 |
| 2026-02-25 | v0.5 | Phase 3 — 苏格拉底式研究工具、自扩展（`/learn`）、宪法治理 |
| 2026-02-25 | v0.6 | 4 个新技能（`/run-bootstrap`、`/run-placebo`、`/run-logit-probit`、`/run-lasso`） |
| 2026-02-26 | v0.7 | Phase 5 — 真实数据复制测试，15 个问题修复，所有 `/run-*` 技能防御性编程加固 |
| 2026-02-26 | v0.8 | Stata 自动批准封装（`run-stata.sh`）、编排协议更新 |
| 2026-02-26 | v0.9 | Stata 错误验证规则 — 强制读取钩子输出，防止日志覆盖误报 |
| 2026-02-26 | v0.10 | 一致性审计 — 修复文档、正则、YAML 前言、交叉引用中的 31 个问题 |
| 2026-02-27 | v0.11 | Phase 6 — 管线编排（`/run-pipeline`）、综合报告（`/synthesis-report`）、编排器 Phase 7 |
| 2026-02-27 | v0.12 | 写作工具 — 4 个新技能（`/translate`、`/polish`、`/de-ai`、`/logic-check`） |
| 2026-02-28 | v0.13 | 技能审计 — 8 个技能按 skill-creator 最佳实践更新 |
| 2026-03-01 | v0.14 | 安全加固 — 全允许 + 拒绝名单权限、`raw-data-guard.py` 钩子、35 条拒绝规则、4 层纵深防御 |
| 2026-03-02 | v0.15 | `/fetch-csmar` 技能（CSMAR API 集成）、esttab→LaTeX 兼容性规则 |
| 2026-03-02 | v0.16 | 修复 Stata `-e` 模式的重复 `.log` 文件 |
| 2026-03-04 | v0.17 | 重构 `data/raw/` 至项目根级别（跨版本共享） |
| 2026-03-06 | v0.18 | 文档同步 — 修复功能计数，对齐 README/ROADMAP 与 CLAUDE.md |
| 2026-03-12 | v0.19 | 重构 — 删除 3 个废弃智能体，36 个技能添加 `name:` 前言和优化触发描述，超大技能提取至 `references/`（渐进式披露），修复 PostToolUse 钩子（绝对路径、SHA-256 哈希、早期退出） |

---

## 致谢

- 模板架构灵感来自 [Pedro H.C. Sant'Anna 的 claude-code-my-workflow](https://github.com/pedrohcgs/claude-code-my-workflow)
- 计量方法遵循 Angrist & Pischke、Callaway & Sant'Anna (2021)、Rambachan & Roth (2023)、Cattaneo, Idrobo & Titiunik (2020) 的指南
- 质量评分框架改编自 AEA 数据编辑器复制标准

---

## 许可证

MIT
