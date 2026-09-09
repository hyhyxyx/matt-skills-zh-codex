# 中文 Codex 技能集适配实施计划

> **For Codex:** 按本计划逐项实施并验证，不省略上游正式技能的内容。

**目标：** 在独立仓库中保留 Matt Pocock 技能集的完整方法论，同时提供适合中文创作者、Windows 和 Codex 的语言、调用、工具及权限适配。

**架构：** 保持上游 `skills/engineering` 与 `skills/productivity` 原样不动，由同步脚本将25个正式技能及全部支持文件完整生成到 Codex 原生目录 `.agents/skills`。生成副本增加统一的 `CODEX-ZH.md` 兼容层、双语发现信息和 Windows 模板；原技能正文、示例与引用完整保留。PowerShell 模板与现有 Bash 模板并存。

**技术栈：** Markdown、YAML、PowerShell、Bash、Git、Codex Agent Skills。

---

### 任务1：建立独立仓库和适配分支

**文件：**

- 使用：`D:\xyx_study\skills`
- 创建：`D:\xyx_study\skills-codex-zh`

1. 从本地上游副本克隆独立仓库。
2. 将官方 GitHub 地址登记为 `upstream`。
3. 创建 `codex/zh-cn` 分支。
4. 确认上游仓库未被修改。

### 任务2：增加统一中文 Codex 兼容层

**文件：**

- 创建：`CODEX-ZH.md`
- 创建：`README-CODEX-ZH.md`
- 创建：`scripts/sync-codex-zh-adapter.ps1`
- 生成：`.agents/skills/<skill-name>/`

1. 规定默认中文交流和中文创作者友好的表达方式。
2. 将 `/skill` 和 “Skill tool” 语义映射为 Codex 的 `$skill-name` 及本地技能加载。
3. 规定 Windows/PowerShell 优先及跨平台回退方式。
4. 明确文件、Git、Issue、Secrets、远程发布等操作的授权边界。
5. 用可重复脚本从上游正式目录生成25个 Codex 原生技能，增加兼容层引用和双语发现信息。

### 任务3：补齐 Windows 原生模板

**文件：**

- 创建：`codex-overrides/wizard/template.ps1`
- 创建：`codex-overrides/diagnosing-bugs/scripts/hitl-loop.template.ps1`
- 生成：`.agents/skills/wizard/template.ps1`
- 生成：`.agents/skills/diagnosing-bugs/scripts/hitl-loop.template.ps1`

1. 保留两个现有 Bash 模板。
2. 在 Codex 生成副本中增加功能等价的 PowerShell 模板。
3. 在生成副本的技能入口中增加按操作系统选择模板的规则。
4. 对 `.env`、GitHub Secrets 和人工输入保留确认与脱敏约束。

### 任务4：验证内容与 Codex 兼容性

**文件：**

- 创建：`scripts/verify-codex-zh.ps1`

1. 验证正式技能数量仍为25。
2. 验证每个技能都有 `name`、双语 `description`、`agents/openai.yaml` 和兼容层引用。
3. 验证所有本地 Markdown 引用均存在，忽略明确的模板占位符。
4. 验证 PowerShell 脚本语法。
5. 验证 Bash 模板仍存在，且上游非正式目录没有进入正式技能集合。
6. 运行 `git diff --check` 并检查敏感内容、生成物和异常大文件。

### 任务5：提交适配分支

1. 复核明确的暂存文件清单。
2. 提交到 `codex/zh-cn`。
3. 不推送远程，报告提交哈希与后续安装方式。
