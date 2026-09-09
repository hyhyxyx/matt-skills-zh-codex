---
name: implement
description: "按照已经确认的规格或任务票实施功能；适用于需求已经清晰并准备编码时。 English: Implement a piece of work based on a spec or set of tickets."
disable-model-invocation: true
---

> [!IMPORTANT]
> **中文 Codex 适配：** 执行本技能前，必须完整读取 [`references/CODEX-ZH.md`](references/CODEX-ZH.md)。下面保留上游方法论的完整内容；兼容规则只增加中文交互、Codex 调用、Windows 工具映射和授权边界。

Implement the work described by the user in the spec or tickets.

Use /tdd where possible, at pre-agreed seams.

Run typechecking regularly, single test files regularly, and the full test suite once at the end.

Once done, use /code-review to review the work.

Commit your work to the current branch.
