# 经济学研究工作流 - 快速参考

## 技能参考（36 个技能）

### 核心分析

| 命令 | 功能 | 使用场景 |
|------|------|----------|
| `/init-project` | 初始化项目结构 | 项目开始 |
| `/data-describe` | 描述性统计（Stata + Python） | 数据清洗后 |
| `/run-did` | DID/TWFE/CS/SDID 全流程（含诊断检验） | 因果估计 |
| `/run-iv` | IV/2SLS 全流程（含一阶段和弱工具变量检验） | 因果估计 |
| `/run-rdd` | RDD 全流程（含带宽敏感性和密度检验） | 因果估计 |
| `/run-panel` | 面板 FE/RE/GMM（含 Hausman、序列相关检验） | 因果估计 |
| `/run-sdid` | 合成 DID（含单位/时间权重和推断） | 因果估计 |
| `/run-bootstrap` | 配对、wild cluster、残差、teffects 自举推断 | 主要结果之后 |
| `/run-placebo` | 时间、结果、工具变量、置换安慰剂检验 | 稳健性检验 |
| `/run-logit-probit` | Logit/Probit、倾向得分、RA/IPW/AIPW、条件 Logit | 二元/处理效应模型 |
| `/run-lasso` | LASSO、双重选择后推断、严格 LASSO、glmnet 匹配 | 变量选择 |
| `/cross-check` | Stata ↔ Python 回归交叉验证（< 0.1%） | 任何回归之后 |
| `/robustness` | 综合稳健性检验套件 | 主要结果之后 |

### 输出与写作

| 命令 | 功能 | 使用场景 |
|------|------|----------|
| `/make-table` | 出版级 LaTeX 表格（AER 或三线表） | 撰写论文前 |
| `/write-section` | 撰写论文章节（中/英期刊规范） | 论文撰写 |
| `/compile-latex` | 运行 pdflatex/bibtex 管线（含错误检查） | 论文编辑后 |
| `/translate` | 中英文学术论文翻译 | 双语项目 |
| `/polish` | 学术论文润色（5 种模式：中/英润色、精炼、压缩、扩展） | 投稿前 |
| `/de-ai` | 检测并去除 AI 写作痕迹 | 投稿前 |
| `/logic-check` | 终审逻辑检查（仅查关键错误） | 投稿前 |

### 审稿与质量

| 命令 | 功能 | 使用场景 |
|------|------|----------|
| `/review-paper` | 模拟三位同行评审 | 投稿前 |
| `/lit-review` | 结构化文献综述（含 BibTeX） | 早期阶段/修改 |
| `/adversarial-review` | 对抗式 critic-fixer 循环（代码、计量、表格）最多 5 轮 | 质量保证 |
| `/score` | 可执行质量评分器（6 个维度，100 分制） | 任何交付物之后 |

### 会话与项目管理

| 命令 | 功能 | 使用场景 |
|------|------|----------|
| `/commit` | 智能 git 提交（类型前缀 + 数据安全警告） | 修改后 |
| `/context-status` | 显示版本、决策、评分、git 状态 | 工作开始时 |
| `/session-log` | 会话启动/结束（MEMORY.md 集成） | 会话边界 |
| `/explore` | 探索沙盒（宽松阈值 >= 60） | 假设检验 |
| `/promote` | 将文件从 `explore/` 提升至 `vN/`（含质量检查） | 探索之后 |

### 研究构思与治理

| 命令 | 功能 | 使用场景 |
|------|------|----------|
| `/interview-me` | 双语苏格拉底式访谈 → 结构化研究提案 | 新研究想法 |
| `/devils-advocate` | 分析前识别策略威胁评估 | 估计之前 |
| `/learn` | 在会话中创建新规则或技能 | 规范化约定 |
| `/fetch-csmar` | 浏览 CSMAR 数据库，通过 API 获取中国股市数据 | 数据收集 |
| `/run-pipeline` | 自动检测方法，编排完整技能管线 | 端到端自动化 |
| `/synthesis-report` | 汇总输出为结构化综合报告（MD + LaTeX） | 评分之后 |

### 参考资源

| 资源 | 功能 | 用法 |
|------|------|------|
| `advanced-stata-patterns.md` | 脉冲响应、Helmert、HHK、k-class、自举、空间滞后 | 由 run-panel/run-iv 自动调用 |

非用户可调用的参考文件，相关技能需要高级 Stata 模式时自动引用。

---

## 智能体参考（9 个智能体）

### 独立智能体

| 智能体 | 角色 |
|--------|------|
| `paper-reviewer` | 模拟期刊审稿人 — 关联 `/review-paper` |
| `robustness-checker` | 建议缺失的稳健性检验 — 关联 `/robustness` |
| `cross-checker` | 比较 Stata 与 Python 结果 — 关联 `/cross-check` |

### 对抗式 Critic-Fixer 对

| Critic | Fixer | 领域 |
|--------|-------|------|
| `code-critic` | `code-fixer` | 代码规范、安全、可复制性 |
| `econometrics-critic` | `econometrics-fixer` | 识别策略、诊断检验、稳健性 |
| `tables-critic` | `tables-fixer` | 表格格式、报告、合规性 |

Critic 只读，不能编辑文件。Fixer 有完全权限但不能给自己评分。

---

## 典型工作流序列

### 研究构思
```
/interview-me → /devils-advocate → /data-describe → /run-{method}
```

### 完整论文管线
```
/init-project → /data-describe → /run-{method} → /cross-check → /robustness
  → /make-table → /write-section → /review-paper → /adversarial-review
  → /score → /synthesis-report → /compile-latex → /commit
```

### 自动化管线（单条命令）
```
/run-pipeline  →  自动检测方法  →  运行完整序列  →  /synthesis-report
```

### 快速回归检查
```
/run-{method} → /cross-check → /score
```

### 修改回复
```
/context-status → （处理审稿意见）→ /adversarial-review → /score → /commit
```

### 探索沙盒
```
/explore → （在 explore/ 中工作）→ /promote → /score
```

### 文献深度调研
```
/lit-review → /write-section（文献综述）
```

---

## 治理机制

### 宪法（`.claude/rules/constitution.md`）

5 条不可变原则 — 始终生效，不可覆盖：
1. 原始数据完整性（`data/raw/` 永不修改）
2. 完全可复制性（每个结果来自代码 + 原始数据）
3. 强制交叉验证（< 0.1%；在 `explore/` 中放宽）
4. 版本保留（`vN/` 永不删除）
5. 评分诚信（如实记录）

### 编排协议

非琐碎任务遵循：**规格 → 计划 → 实施 → 验证 → 审查 → 修复 → 评分 → 报告**

Phase 0（规格）在以下情况触发：任务涉及 >= 3 个文件、改变识别策略、创建技能/规则/智能体、或修改协议本身。每个任务只写一次 — 审查循环从「计划」重新开始。

"直接做"模式：琐碎任务（<= 2 个文件，评分 >= 80，无严重发现）跳过多轮循环。

### 权限与安全

**模式**：拒绝名单（共享）+ 可选全允许（个人）。
免提示：`cp .claude/settings.local.json.example .claude/settings.local.json`

**拒绝规则**（35 条）：`data/raw/**`（Edit/Write/Bash）、破坏性 git、`rm -rf`、`*.env`、`*.credentials*`、`.claude/hooks/**`、`.claude/scripts/**`、`.claude/settings.json`。

**防御层次**：
1. `deny` 规则 → 工具级字符串匹配
2. `raw-data-guard.py` → PostToolUse 快照对比 `data/raw/`
3. `attrib +R` → 操作系统级（手动设置）
4. 宪法 + `bash-conventions.md` → 行为约束

**Bash 规则**：禁止 `&&`/`||`/`;` 链式命令。使用独立工具调用。使用绝对路径。禁止 `2>/dev/null`。

---

## 质量评分

| 分数 | 含义 | 动作 |
|------|------|------|
| >= 95 | 可发表 | 继续 |
| >= 90 | 小修 | 再来一轮 |
| >= 80 | 大修 | 重新进入实施 |
| < 80 | 重做 | 重新进入计划 |

评分来源：`/score`（自动化，6 个维度）和 `/adversarial-review`（critic 智能体）。

---

## 关键约定

### 文件路径
- 原始数据（只读，项目级）：`data/raw/`
- 清洗后数据：`vN/data/clean/`
- Stata 代码：`vN/code/stata/`
- Python 代码：`vN/code/python/`
- 所有输出：`vN/output/`
- 表格：`vN/output/tables/`
- 图表：`vN/output/figures/`
- 论文：`vN/paper/`

### Stata 执行（Git Bash）
```bash
bash .claude/scripts/run-stata.sh "<project_dir>" "code/stata/script.do"
```
- 封装脚本使用 `-e`（自动退出），内含自动日志检查
- 备用：`"D:\Stata18\StataMP-64.exe" -e do "code/stata/script.do"`
- **禁止用 `-b`**（需手动确认）或 **`/e`**（Git Bash 路径冲突）
- 非零退出码或日志中出现 `r(xxx)` = 失败

### 版本管理
- 每次大修改使用独立的 `vN/` 目录
- `_VERSION_INFO.md` 记录版本元数据
- `docs/CHANGELOG.md` 记录项目级变更

### 命名约定
- Stata do 文件：`01_clean_data.do`、`02_desc_stats.do`、`03_reg_main.do`、...
- 输出表格：`tab_main_results.tex`、`tab_robustness.tex`、...
- 输出图表：`fig_event_study.pdf`、`fig_parallel_trends.pdf`、...

---

## 常见操作

### 添加稳健性检验
1. 运行 `/robustness` 获取建议
2. 在 `04_robustness.do` 中实施建议的检验
3. 运行 `/cross-check` 验证
4. 运行 `/make-table` 格式化结果

### 回应审稿意见
1. 创建新版本目录 `vN+1/`
2. 复制并修改相关代码
3. 运行 `/robustness` 添加额外检验
4. 运行 `/make-table` 更新表格
5. 运行 `/write-section` 撰写回复信
6. 运行 `/review-paper` 自检

### 交叉验证工作流
1. 通过 `/run-{method}` 在 Stata 中运行回归
2. 运行 `/cross-check` 在 Python 中复制
3. 审查系数对比表
4. 容差：系数差异 < 0.1%（严格），标准误差异 < 5%

---

## 故障排除

| 问题 | 解决方案 |
|------|----------|
| Stata 日志显示错误 | 阅读完整日志，修复 do 文件，重新运行 |
| 交叉验证不匹配 | 检查聚类、样本限制、变量定义 |
| LaTeX 表格编译失败 | 检查 `\input{}` 路径和缺失的宏包 |
| 版本冲突 | 始终在最新的 `vN/` 目录中工作 |
| 探索结果太粗糙 | 使用 `/promote` 通过质量门控提升 |
