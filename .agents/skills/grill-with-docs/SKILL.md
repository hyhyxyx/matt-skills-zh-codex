---
name: grill-with-docs
description: "通过连续追问澄清设计，同时沉淀领域词汇和架构决策文档；适用于需要在项目内留下决策依据的方案讨论。 English: A relentless interview to sharpen a plan or design, which also creates docs (ADR's and glossary) as we go."
disable-model-invocation: true
---

> [!IMPORTANT]
> **中文 Codex 适配：** 执行本技能前，必须完整读取 [`references/CODEX-ZH.md`](references/CODEX-ZH.md)。下面保留上游方法论的完整内容；兼容规则只增加中文交互、Codex 调用、Windows 工具映射和授权边界。

Call the Skill tool twice, for "grilling" and "domain-modeling".

## 中文访谈输出校验

当用户使用中文时，所有面向用户的标题、问题、选项、推荐、分隔说明、进度更新和阶段总结均使用完整、自然的简体中文。代码标识符、命令、API 名称、文件名、产品名和必须精确保留的领域缩写可以保持原文，并在首次出现时用中文说明。

每轮发送前检查当前回复：

1. 问题编号连续，选项统一使用 `A`、`B`、`C` 等标签，推荐项与选项一一对应。
2. 非代码区域没有无语义的英文片段、HTML 残片、模板占位符、重复标签、异常字符或未完成句子。
3. 中文句子完整通顺，上一轮答案的归纳与下一轮问题之间有清晰分隔。
4. 写入 `CONTEXT.md` 和 ADR 的中文正文遵循同样的语言规则。

任一项不符合时，先重写完整回复，再发送给用户。
