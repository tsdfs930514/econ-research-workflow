# 测试问题日志 (ISSUES_LOG)

> 2026-02-25 执行全部 5 个测试后整理

---

## 汇总表格

| # | 测试 | 错误信息 | 根本原因 | 修复方案 | Skill 改进建议 |
|---|------|----------|----------|----------|----------------|
| 1 | test1-did | `boottest` r(198) | boottest 不支持 reghdfe 吸收多组 FE | `cap noisily` 包裹 | /run-did 中注明 boottest 与多重 FE 不兼容 |
| 2 | test1-did | csdid/bacondecomp 可能报错 | 包依赖复杂，版本敏感 | 预防性 `cap noisily` 包裹 | /run-did 的 csdid 代码块应默认加 `cap noisily` |
| 3 | test2-rdd | CJM density test p-value = . (缺失) | rddensity 返回值可能未被正确捕获 | 非致命，结果仍有效 | /run-rdd 中检查 `e(p)` 是否缺失并给出提示 |
| 4 | test3-iv | First-stage F = 2.24 (旧数据) | 旧 DGP 中 SCI 仅有随机噪声，FE 吸收后几乎无变异 | 重写 DGP：县级 slope x 年份偏差提供 FE 残差变异 | /run-iv 生成合成数据时应验证 FE 后的 partial F |
| 5 | test3-iv | `tab treatment, missing` 对连续变量报错 | 连续 treatment 产生太多唯一值 | 改为 `summarize treatment, detail` | /run-iv 模板应区分二值/连续 treatment |
| 6 | test4-panel | `ssc install xtserial` r(601) | xtserial 已从 SSC 移除 | 改用 `cap ssc install` | /run-panel Required Packages 移除 xtserial |
| 7 | test4-panel | `xtserial` command not found r(199) | Stata 18 未内置 xtserial | `cap noisily` 包裹并给出跳过提示 | /run-panel 中 Wooldridge test 应加 cap noisily |
| 8 | test4-panel | xtcsd / xttest3 不可用 | SSC 安装可能失败 | `cap noisily` 包裹 | /run-panel 安装脚本应检查 `which` 命令确认安装 |
| 9 | test4-panel | Hausman chi2 = -808, p = 1 | FE 强烈优于 RE 时方差矩阵差不正定 | 属已知 Stata 行为，不影响结论 | /run-panel 应注明负 chi2 的解释 |
| 10 | 全局 | Stata `/b` 在 bash 中被解释为路径 | Git Bash 将 `/b` 视为 Unix 路径前缀 | 改用 `-b` flag + Unix 风格路径 | CLAUDE.md 和所有 skill 的 Stata 执行命令统一为 `-e`（自动退出） |

---

## 按测试详细记录

### test1-did

**错误 1：boottest 与多重吸收 FE 不兼容**
- 错误信息：`Doesn't work after reghdfe with more than one set of absorbed fixed effects` → r(198)
- 位置：`01_did_analysis.do` 第 142-144 行
- 根本原因：boottest 包的限制，无法在 reghdfe 吸收 `state_id` + `year` 两组 FE 后运行
- 修复：在 `reghdfe` 和 `boottest` 前加 `cap noisily`
- Skill 建议：`/run-did` 模板中，Wild Cluster Bootstrap 部分应改用单 FE 的 `xtreg` 或注明与多重 FE 的不兼容性

**错误 2：csdid / bacondecomp 风险**
- 位置：`01_did_analysis.do` 第 107-124 行
- 根本原因：csdid 和 bacondecomp 包版本更新频繁，容易因依赖问题报错
- 修复：所有 csdid/csdid_stats/csdid_plot/bacondecomp 调用均加 `cap noisily`
- Skill 建议：`/run-did` 中 CS-DiD 和 Bacon decomposition 部分默认使用 `cap noisily`

---

### test2-rdd

**问题：CJM density test p-value 缺失**
- 现象：`CJM density test p-value: .`
- 位置：`01_rdd_analysis.do` 密度测试部分
- 可能原因：rddensity 包的返回值在某些版本中存放位置不同
- 影响：非致命错误，主要 RD 估计仍然正确（1.76 conventional, 1.64 robust）
- Skill 建议：`/run-rdd` 应在捕获 rddensity 返回值时加入多种尝试（`e(p)`, `r(p)`, scalar）

---

### test3-iv

**错误 3：弱工具变量 (旧 DGP)**
- 错误信息：First-Stage F = 2.24（远低于 10 的经验阈值）
- 根本原因：旧 DGP 中 SCI = state_base + random_noise(sd=0.2)。吸收 state FE 和 year FE 后，仅剩 noise 项，几乎无法预测 treatment
- 修复：重写 DGP，引入 county-specific slope：`sci = state_base + county_slope * (year - year_mean) + noise`。county_slope 在州内变化，乘以时间偏差后产生不被 state/year FE 吸收的变异
- 修复后结果：Partial F = 1523（Python 验证）, Stata First-stage F = 5316
- Skill 建议：`/run-iv` 生成合成数据时应包含 FE 后 partial F 的验证步骤

**错误 4：tab 连续变量**
- 错误信息：可能出现 r(134) "too many values"
- 位置：`01_iv_analysis.do` 第 27 行 `tab treatment, missing`
- 修复：改为 `summarize treatment, detail`
- Skill 建议：`/run-iv` 模板应根据 treatment 变量类型选择 tab 或 summarize

---

### test4-panel

**错误 5：xtserial SSC 安装失败**
- 错误信息：`ssc install: "xtserial" not found at SSC` → r(601)
- 根本原因：xtserial 已从 SSC 存档中移除（可能因作者变更或合并入官方 Stata）
- 影响：r(601) 导致安装脚本中断，后续包（xtcsd, xttest3）也未安装
- 修复 1：所有 `ssc install` 前加 `cap`，避免单个失败中断全部安装
- 修复 2：分析脚本中 `xtserial` 调用加 `cap noisily` 并给出跳过提示
- Skill 建议：`/run-panel` Required Packages 中移除 xtserial，或标注"可能已内置"

**错误 6：xtcsd / xttest3 命令不可用**
- 现象：`xtcsd not available`, `xttest3 not available`
- 根本原因：SSC 安装被 xtserial 的 r(601) 中断，这两个包未能安装
- 修复：安装脚本已加 `cap`，分析脚本已加 `cap noisily`
- Skill 建议：安装脚本中每个包应独立安装（`cap` 前缀），并在末尾用 `which` 验证

**问题 7：Hausman test 负 chi2**
- 现象：`Hausman chi2 = -807.98, p-value = 1`
- 根本原因：当 FE 和 RE 的方差矩阵差不正定时，Stata 计算出负 chi2 并设 p=1
- 解释：通常发生在 FE 强烈优于 RE 时（firm FE 与回归变量高度相关，corr=0.87）
- 影响：不影响结论——FE 仍然是正确选择
- Skill 建议：`/run-panel` 应注明 Hausman test 负 chi2 的含义和处理方式

---

### test5-full-pipeline

**预防性修复：assert treated == post**
- 位置：`01_clean_data.do` 第 110 行
- 修复：添加 `if !missing(treated)` 条件防止 missing 值导致断言失败
- 运行结果：无错误，全部 4 个子脚本成功

---

## 全局问题

### Stata 批处理模式命令格式

**问题**：在 Git Bash 环境中，`"D:\Stata18\StataMP-64.exe" /b do "script.do"` 会导致 `/b` 被解释为 Unix 路径。Stata 收到的命令变为 `B:/ do script.do`，报错 `command B is unrecognized` → r(199)

**正确格式**：
```bash
"D:\Stata18\StataMP-64.exe" -e do "code/stata/script.do"
```

**错误格式**：
```bash
"D:\Stata18\StataMP-64.exe" /b do "script.do"   # /b 被解释为路径
"D:\Stata18\StataMP-64.exe" /e do "script.do"   # /e 同理
```

**Skill 建议**：CLAUDE.md 和所有 skill 文件中的 Stata Execution Command 应统一为 `-b` + Unix 路径格式

---

## 推荐的 Skill 改进项

| 优先级 | Skill 文件 | 改进内容 |
|--------|-----------|----------|
| 高 | CLAUDE.md | Stata 执行命令统一为 `"D:\Stata18\StataMP-64.exe" -e do`（已完成） |
| 高 | /run-panel | Required Packages 移除 xtserial；安装脚本加 `cap` |
| 高 | /run-panel | 诊断测试 (xtserial, xtcsd, xttest3) 全部加 `cap noisily` |
| 中 | /run-did | csdid/bacondecomp 代码块默认加 `cap noisily` |
| 中 | /run-did | boottest 注明与 reghdfe 多重 FE 不兼容 |
| 中 | /run-iv | 安装顺序注明 ranktest 必须在 ivreg2 和 ivreghdfe 之前 |
| 中 | /run-iv | 合成数据应验证 FE 后 partial F > 23 |
| 低 | /run-rdd | rddensity p-value 捕获添加多种尝试路径 |
| 低 | /run-panel | 注明 Hausman test 负 chi2 的含义 |
