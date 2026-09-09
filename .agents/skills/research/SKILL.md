---
name: research
description: "基于官方文档、源码和规范等一手资料开展调研并形成带引用的Markdown报告。 English: Investigate a question against high-trust primary sources and capture the findings as a Markdown file in the repo. Use when the user wants a topic researched, docs or API facts gathered, or reading legwork delegated to a background agent."
---

> [!IMPORTANT]
> **中文 Codex 适配：** 执行本技能前，必须完整读取 [`references/CODEX-ZH.md`](references/CODEX-ZH.md)。下面保留上游方法论的完整内容；兼容规则只增加中文交互、Codex 调用、Windows 工具映射和授权边界。

Spin up a **background agent** to do the research, so you keep working while it reads.

Its job:

1. Investigate the question against **primary sources** (official docs, source code, specs, first-party APIs), not a secondary write-up of them. Follow every claim back to the source that owns it.
2. Write the findings to a single Markdown file, citing each claim's source.
3. Save it where the repo already keeps such notes; match the existing convention, and if there is none, put it somewhere sensible and say where.
