[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$targetRoot = [IO.Path]::GetFullPath((Join-Path $repoRoot '.agents\skills'))
$adapterPath = Join-Path $repoRoot 'CODEX-ZH.md'
$utf8NoBom = [Text.UTF8Encoding]::new($false)

if (-not (Test-Path -LiteralPath $adapterPath -PathType Leaf)) {
  throw "缺少统一兼容规则：$adapterPath"
}

$descriptions = [ordered]@{
  'ask-matt' = '为当前问题选择合适的技能或工作流；适用于不知道下一步该使用哪个技能时。'
  'code-review' = '从代码规范和需求规格两个维度审查指定基准后的改动；适用于分支、PR或工作区代码评审。'
  'codebase-design' = '使用深模块方法设计或改善代码接口、接缝和可测试性；适用于模块设计和架构重构。'
  'diagnosing-bugs' = '用可重复反馈闭环诊断疑难故障和性能回退；适用于报错、失败、卡顿、抖动或难以复现的问题。'
  'domain-modeling' = '建立并校准项目领域语言、CONTEXT文档和架构决策记录；适用于术语、概念关系和关键决策。'
  'grill-with-docs' = '通过连续追问澄清设计，同时沉淀领域词汇和架构决策文档；适用于需要在项目内留下决策依据的方案讨论。'
  'implement' = '按照已经确认的规格或任务票实施功能；适用于需求已经清晰并准备编码时。'
  'improve-codebase-architecture' = '扫描代码库中的深模块改进机会并生成可视化报告；适用于主动检查架构质量。'
  'prototype' = '制作一次性逻辑或界面原型来回答设计问题；适用于需要先看效果或验证状态模型时。'
  'research' = '基于官方文档、源码和规范等一手资料开展调研并形成带引用的Markdown报告。'
  'resolving-merge-conflicts' = '依据双方原始意图解决正在进行的Git合并或变基冲突。'
  'setup-matt-pocock-skills' = '为当前仓库配置问题跟踪器、分诊标签和领域文档布局；首次使用工程技能集前运行。'
  'tdd' = '采用红灯、绿灯循环进行测试驱动开发；适用于明确要求测试优先、集成测试或红绿重构时。'
  'to-spec' = '把当前对话整理成可实施规格并发布到已配置的问题跟踪器。'
  'to-tickets' = '把方案或规格拆成带依赖关系的纵向任务票，并发布到已配置的问题跟踪器。'
  'triage' = '按分诊状态机核验、分类并整理外部问题或PR，生成可供智能体执行的任务说明。'
  'wayfinder' = '把超出单次会话的大型模糊工作规划为决策任务地图，并逐步消除关键不确定性。'
  'wizard' = '生成人机协作的交互式配置向导；适用于必须由用户完成的账号、凭据、控制台或迁移步骤。'
  'grill-me' = '通过持续访谈把计划、设计或想法中的隐含分支全部澄清。'
  'grilling' = '对计划、决定或想法进行逐轮追问和压力测试，直到没有未处理的决策分支。'
  'handoff' = '把当前对话压缩成可供另一个智能体或新会话继续执行的交接文档。'
  'teach' = '在当前工作区中通过互动课程、练习和学习记录教授一项技能或概念。'
  'to-questionnaire' = '把需要由其他人回答的决策缺口整理成结构化问卷。'
  'wait-what' = '当上一条说明没有讲清楚时，结合项目语境用更直白的中文重新解释。'
  'writing-for-agents' = '编写或修改供智能体读取的技能、AGENTS.md、CLAUDE.md及其引用文档。'
}

$displayNames = [ordered]@{
  'ask-matt' = '技能导航'
  'code-review' = '代码审查'
  'codebase-design' = '代码库设计'
  'diagnosing-bugs' = '故障诊断'
  'domain-modeling' = '领域建模'
  'grill-with-docs' = '深度澄清并沉淀文档'
  'implement' = '按规格实施'
  'improve-codebase-architecture' = '改善代码库架构'
  'prototype' = '原型验证'
  'research' = '一手资料调研'
  'resolving-merge-conflicts' = '解决合并冲突'
  'setup-matt-pocock-skills' = '初始化技能配置'
  'tdd' = '测试驱动开发'
  'to-spec' = '生成规格'
  'to-tickets' = '拆分任务票'
  'triage' = '需求与问题分诊'
  'wayfinder' = '大型工作导航'
  'wizard' = '交互式配置向导'
  'grill-me' = '深度追问'
  'grilling' = '深度澄清'
  'handoff' = '会话交接'
  'teach' = '互动教学'
  'to-questionnaire' = '生成调研问卷'
  'wait-what' = '重新解释'
  'writing-for-agents' = '编写智能体文档'
}

$sourceSkills = @()
foreach ($bucket in @('engineering', 'productivity')) {
  $bucketPath = Join-Path $repoRoot "skills\$bucket"
  foreach ($skillFile in Get-ChildItem -LiteralPath $bucketPath -Filter 'SKILL.md' -File -Recurse) {
    $sourceSkills += [pscustomobject]@{
      Name = $skillFile.Directory.Name
      Source = $skillFile.Directory.FullName
    }
  }
}

$sourceNames = @($sourceSkills.Name | Sort-Object)
$expectedNames = @($descriptions.Keys | Sort-Object)
if ($sourceNames.Count -ne 25 -or (Compare-Object $sourceNames $expectedNames)) {
  throw '正式技能清单与中文映射不一致；请先更新映射再生成。'
}

New-Item -ItemType Directory -Force -Path $targetRoot | Out-Null

function Assert-SafeGeneratedPath {
  param([Parameter(Mandatory)][string]$Path)
  $fullPath = [IO.Path]::GetFullPath($Path)
  $prefix = $targetRoot.TrimEnd('\') + '\'
  if (-not $fullPath.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
    throw "拒绝操作生成目录以外的路径：$fullPath"
  }
}

function Convert-ToYamlDoubleQuoted {
  param([Parameter(Mandatory)][string]$Value)
  return $Value.Replace('\', '\\').Replace('"', '\"')
}

$adapterBlock = @'
> [!IMPORTANT]
> **中文 Codex 适配：** 执行本技能前，必须完整读取 [`references/CODEX-ZH.md`](references/CODEX-ZH.md)。下面保留上游方法论的完整内容；兼容规则只增加中文交互、Codex 调用、Windows 工具映射和授权边界。

'@

foreach ($skill in $sourceSkills) {
  $name = $skill.Name
  $target = Join-Path $targetRoot $name
  Assert-SafeGeneratedPath -Path $target
  if (Test-Path -LiteralPath $target) {
    Remove-Item -LiteralPath $target -Recurse -Force
  }
  New-Item -ItemType Directory -Force -Path $target | Out-Null
  Copy-Item -Path (Join-Path $skill.Source '*') -Destination $target -Recurse -Force
  $generatedReferences = Join-Path $target 'references'
  New-Item -ItemType Directory -Force -Path $generatedReferences | Out-Null
  Copy-Item -LiteralPath $adapterPath -Destination (Join-Path $generatedReferences 'CODEX-ZH.md') -Force

  $skillPath = Join-Path $target 'SKILL.md'
  $content = [IO.File]::ReadAllText($skillPath)
  $descriptionMatch = [regex]::Match($content, '(?m)^description:\s*(.+)$')
  if (-not $descriptionMatch.Success) {
    throw "技能缺少 description：$name"
  }
  $originalDescription = $descriptionMatch.Groups[1].Value.Trim().Trim('"').Trim("'").Replace('\"', '"')
  $bilingualDescription = "$($descriptions[$name]) English: $originalDescription"
  $escapedDescription = Convert-ToYamlDoubleQuoted -Value $bilingualDescription
  $descriptionRegex = [regex]::new('(?m)^description:\s*.+$')
  $content = $descriptionRegex.Replace($content, "description: `"$escapedDescription`"", 1)
  $frontmatterRegex = [regex]::new(
    '\A(---\r?\n.*?\r?\n---\r?\n)',
    [Text.RegularExpressions.RegexOptions]::Singleline
  )
  $content = $frontmatterRegex.Replace(
    $content,
    { param($match) $match.Groups[1].Value + "`n" + $adapterBlock },
    1
  )

  if ($name -eq 'wizard') {
    $content += @'

## 中文 Codex 的 Windows 模板选择

在 Windows 原生环境中，使用 `template.ps1`；在 Git Bash、WSL、Linux 或 macOS 中，继续使用完整保留的 `template.sh`。两份模板提供相同阶段、人工确认、环境变量写入和 GitHub Secrets 能力。先根据当前系统选择模板，再执行上面的完整流程。
'@
  }
  if ($name -eq 'diagnosing-bugs') {
    $content += @'

## 中文 Codex 的 Windows 人工闭环

需要人工点击的最后手段在 Windows 原生环境中使用 `scripts/hitl-loop.template.ps1`；在 Git Bash、WSL、Linux 或 macOS 中继续使用完整保留的 `scripts/hitl-loop.template.sh`。捕获内容仍必须先脱敏。
'@
  }
  [IO.File]::WriteAllText($skillPath, $content, $utf8NoBom)

  $openaiPath = Join-Path $target 'agents\openai.yaml'
  if (-not (Test-Path -LiteralPath $openaiPath -PathType Leaf)) {
    throw "技能缺少 agents/openai.yaml：$name"
  }
  $openai = [IO.File]::ReadAllText($openaiPath)
  $displayMatch = [regex]::Match($openai, '(?m)^\s{2}display_name:\s*"?([^"\r\n]+)"?\s*$')
  $shortMatch = [regex]::Match($openai, '(?m)^\s{2}short_description:\s*"?([^"\r\n]+)"?\s*$')
  if (-not $displayMatch.Success -or -not $shortMatch.Success) {
    throw "技能 UI 元数据不完整：$name"
  }
  $originalDisplay = $displayMatch.Groups[1].Value.Trim()
  $originalShort = $shortMatch.Groups[1].Value.Trim()
  $displayRegex = [regex]::new('(?m)^\s{2}display_name:.*$')
  $shortRegex = [regex]::new('(?m)^\s{2}short_description:.*$')
  $openai = $displayRegex.Replace($openai, "  display_name: `"$($displayNames[$name]) / $originalDisplay`"", 1)
  $openai = $shortRegex.Replace($openai, "  short_description: `"$($descriptions[$name]) / $originalShort`"", 1)
  if (-not $openai.StartsWith('# CODEX_ZH_ADAPTED: v1')) {
    $openai = "# CODEX_ZH_ADAPTED: v1`n$openai"
  }
  [IO.File]::WriteAllText($openaiPath, $openai, $utf8NoBom)

  $override = Join-Path $repoRoot "codex-overrides\$name"
  if (Test-Path -LiteralPath $override -PathType Container) {
    Copy-Item -Path (Join-Path $override '*') -Destination $target -Recurse -Force
  }
}

Write-Host "已生成 $($sourceSkills.Count) 个中文 Codex 技能：$targetRoot"
