---
name: handoff
description: "把当前对话压缩成可供另一个智能体或新会话继续执行的交接文档。 English: Compact the current conversation into a handoff document for another agent to pick up."
argument-hint: "What will the next session be used for?"
disable-model-invocation: true
---

> [!IMPORTANT]
> **中文 Codex 适配：** 执行本技能前，必须完整读取 [`references/CODEX-ZH.md`](references/CODEX-ZH.md)。下面保留上游方法论的完整内容；兼容规则只增加中文交互、Codex 调用、Windows 工具映射和授权边界。

Write a handoff document summarising the current conversation so a fresh agent can continue the work. Save to the temporary directory of the user's OS - not the current workspace.

Include a "suggested skills" section in the document, naming which skills the next agent should call the Skill tool for.

Do not duplicate content already captured in other artifacts (specs, plans, ADRs, issues, commits, diffs). Reference them by path or URL instead.

Redact any sensitive information, such as API keys, passwords, or personally identifiable information.

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the doc accordingly.
