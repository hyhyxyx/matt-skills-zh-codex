# Matt Pocock Skills 中文 Codex 适配版

这是 `mattpocock/skills` 的独立中文 Codex 适配分支。它完整保留上游25个正式技能及支持文件，并增加：

- 简体中文交互、中文触发描述，以及中文访谈发送前检查；
- Codex `$skill-name` 调用映射；
- Codex 工具与协作能力映射；
- Windows/PowerShell 原生模板；
- 对 Git、Issue、Secrets、发布和远程写入的授权边界；
- 可重复执行的适配与完整性验证脚本。

统一规则见 [CODEX-ZH.md](./CODEX-ZH.md)。原作者的方法论、流程、例子与参考资料仍保留在各技能目录中。

## 当前范围

- 正式技能：`skills/engineering` 与 `skills/productivity`，共25个。
- 保留但不作为正式安装集合：`skills/in-progress` 与 `skills/misc`。
- 上游：`https://github.com/mattpocock/skills.git`

## Codex 调用

在 Codex 中通过 `$skill-name` 显式调用，例如：

```text
$diagnosing-bugs 帮我诊断 Electron 桌面窗口为什么抖动。
```

允许自动调用的技能也可以根据双语 `description` 匹配中文请求。显式调用策略仍保留原技能的 `agents/openai.yaml` 设置。

## 本地使用

Codex 会从仓库或用户的 `.agents/skills` 目录发现技能。安装前先运行：

```powershell
pwsh -NoProfile -File .\scripts\verify-codex-zh.ps1
```

当前仓库是维护源。`.agents/skills` 下每个目录都是可独立安装的完整技能，已经包含兼容规则副本。把需要的技能目录复制或链接到目标 `.agents/skills` 后，Codex 即可发现；如果界面没有立即刷新，重启 Codex。

## 同步上游

同步新的上游内容后，运行：

```powershell
pwsh -NoProfile -File .\scripts\sync-codex-zh-adapter.ps1
pwsh -NoProfile -File .\scripts\verify-codex-zh.ps1
```

适配脚本只处理正式技能，不会把 `in-progress` 或 `misc` 加入正式集合。
