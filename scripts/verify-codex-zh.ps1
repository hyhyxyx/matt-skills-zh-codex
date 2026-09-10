[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$generatedRoot = Join-Path $repoRoot '.agents\skills'
$errors = [Collections.Generic.List[string]]::new()

$expected = @(
  'ask-matt', 'code-review', 'codebase-design', 'diagnosing-bugs',
  'domain-modeling', 'grill-with-docs', 'implement',
  'improve-codebase-architecture', 'prototype', 'research',
  'resolving-merge-conflicts', 'setup-matt-pocock-skills', 'tdd',
  'to-spec', 'to-tickets', 'triage', 'wayfinder', 'wizard', 'grill-me',
  'grilling', 'handoff', 'teach', 'to-questionnaire', 'wait-what',
  'writing-for-agents'
) | Sort-Object

$generated = @(
  Get-ChildItem -LiteralPath $generatedRoot -Directory -ErrorAction SilentlyContinue |
    Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md') } |
    Select-Object -ExpandProperty Name |
    Sort-Object
)

if ($generated.Count -ne 25) {
  $errors.Add("正式技能数量应为25，实际为$($generated.Count)。")
}
foreach ($difference in @(Compare-Object $expected $generated)) {
  $errors.Add("正式技能清单不一致：$($difference.InputObject) $($difference.SideIndicator)")
}

foreach ($name in $expected) {
  $skillDir = Join-Path $generatedRoot $name
  $skillPath = Join-Path $skillDir 'SKILL.md'
  $openaiPath = Join-Path $skillDir 'agents\openai.yaml'
  if (-not (Test-Path -LiteralPath $skillPath -PathType Leaf)) {
    $errors.Add("缺少 $name/SKILL.md")
    continue
  }
  $content = [IO.File]::ReadAllText($skillPath)
  if ($content -notmatch '(?m)^name:\s*[^\s]+\s*$') {
    $errors.Add("$name 缺少有效 name。")
  }
  if ($content -notmatch '(?m)^description:\s*.*[\p{IsCJKUnifiedIdeographs}].*$') {
    $errors.Add("$name 缺少中文 description。")
  }
  if ($content -notmatch 'references/CODEX-ZH\.md') {
    $errors.Add("$name 没有引用统一兼容规则。")
  }
  if (-not (Test-Path -LiteralPath (Join-Path $skillDir 'references\CODEX-ZH.md') -PathType Leaf)) {
    $errors.Add("$name 缺少可独立安装的兼容规则副本。")
  }
  if ($name -eq 'grill-with-docs') {
    foreach ($requiredInstruction in @(
      '## 中文访谈输出校验',
      '每轮发送前检查当前回复',
      '任一项不符合时，先重写完整回复'
    )) {
      if (-not $content.Contains($requiredInstruction)) {
        $errors.Add("grill-with-docs 缺少中文访谈输出规则：$requiredInstruction")
      }
    }
  }
  if (-not (Test-Path -LiteralPath $openaiPath -PathType Leaf)) {
    $errors.Add("$name 缺少 agents/openai.yaml。")
  } else {
    $openai = [IO.File]::ReadAllText($openaiPath)
    if ($openai -notmatch 'CODEX_ZH_ADAPTED' -or $openai -notmatch '[\p{IsCJKUnifiedIdeographs}]') {
      $errors.Add("$name 的 OpenAI UI 元数据未完成中文适配。")
    }
  }

  foreach ($match in [regex]::Matches($content, '\[[^\]]+\]\(([^)]+)\)')) {
    $target = $match.Groups[1].Value
    if ($target -match '^(https?://|mailto:|#)' -or $target -eq 'link') {
      continue
    }
    $cleanTarget = ($target -split '#')[0]
    if ([string]::IsNullOrWhiteSpace($cleanTarget)) {
      continue
    }
    $resolved = Join-Path $skillDir $cleanTarget
    if (-not (Test-Path -LiteralPath $resolved)) {
      $errors.Add("$name 存在无效本地引用：$target")
    }
  }
}

foreach ($required in @(
  '.agents\skills\wizard\template.sh',
  '.agents\skills\wizard\template.ps1',
  '.agents\skills\diagnosing-bugs\scripts\hitl-loop.template.sh',
  '.agents\skills\diagnosing-bugs\scripts\hitl-loop.template.ps1'
)) {
  if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $required) -PathType Leaf)) {
    $errors.Add("缺少跨平台模板：$required")
  }
}

$upstreamRef = 'upstream/main'
git -C $repoRoot rev-parse --verify --quiet "$upstreamRef^{commit}" | Out-Null
if ($LASTEXITCODE -ne 0) {
  $errors.Add("缺少 $upstreamRef，无法验证上游正式内容是否完整保留。")
  $sourceFiles = @()
} else {
  $sourceFiles = @(
    git -C $repoRoot ls-tree -r --name-only $upstreamRef -- skills/engineering skills/productivity
  )
}
foreach ($sourceFile in $sourceFiles) {
  if ($sourceFile -notmatch '^skills/(engineering|productivity)/([^/]+)/(.+)$') {
    continue
  }
  $skillName = $Matches[2]
  if ($expected -notcontains $skillName) {
    continue
  }
  $relativeWithinSkill = $Matches[3].Replace('/', '\')
  $generatedFile = Join-Path (Join-Path $generatedRoot $skillName) $relativeWithinSkill
  if (-not (Test-Path -LiteralPath $generatedFile)) {
    $errors.Add("上游正式内容没有进入生成技能：$sourceFile")
    continue
  }

  $sourceWorkingFile = Join-Path $repoRoot $sourceFile.Replace('/', '\')
  if ($relativeWithinSkill -eq 'SKILL.md') {
    $sourceContent = [IO.File]::ReadAllText($sourceWorkingFile)
    $generatedContent = [IO.File]::ReadAllText($generatedFile)
    $sourceFrontmatter = [regex]::Match(
      $sourceContent,
      '\A---\r?\n(.*?)\r?\n---\r?\n',
      [Text.RegularExpressions.RegexOptions]::Singleline
    )
    if (-not $sourceFrontmatter.Success) {
      $errors.Add("上游技能 frontmatter 无法解析：$sourceFile")
      continue
    }
    $sourceBody = $sourceContent.Substring($sourceFrontmatter.Length)
    if (-not $generatedContent.Contains($sourceBody)) {
      $errors.Add("生成技能没有完整保留上游正文：$sourceFile")
    }
    $sourceDescription = [regex]::Match($sourceFrontmatter.Groups[1].Value, '(?m)^description:\s*(.+)$').Groups[1].Value.Trim().Trim('"').Trim("'").Replace('\"', '"')
    $normalizedGeneratedContent = $generatedContent.Replace('\"', '"')
    if (-not $normalizedGeneratedContent.Contains($sourceDescription)) {
      $errors.Add("生成技能没有保留上游 description：$sourceFile")
    }
  } elseif ($relativeWithinSkill -eq 'agents\openai.yaml') {
    $sourceOpenAI = [IO.File]::ReadAllText($sourceWorkingFile)
    $generatedOpenAI = [IO.File]::ReadAllText($generatedFile)
    foreach ($field in @('display_name', 'short_description')) {
      $value = [regex]::Match($sourceOpenAI, "(?m)^\s{2}${field}:\s*`"?([^`"\r\n]+)`"?\s*$").Groups[1].Value.Trim()
      if ([string]::IsNullOrWhiteSpace($value) -or -not $generatedOpenAI.Contains($value)) {
        $errors.Add("生成 UI 元数据没有保留上游 ${field}：$sourceFile")
      }
    }
  } else {
    $sourceHash = (Get-FileHash -LiteralPath $sourceWorkingFile -Algorithm SHA256).Hash
    $generatedHash = (Get-FileHash -LiteralPath $generatedFile -Algorithm SHA256).Hash
    if ($sourceHash -ne $generatedHash) {
      $errors.Add("无需适配的上游文件发生变化：$sourceFile")
    }
  }
}

foreach ($scriptPath in @(
  (Join-Path $repoRoot 'scripts\sync-codex-zh-adapter.ps1'),
  (Join-Path $repoRoot 'scripts\verify-codex-zh.ps1'),
  (Join-Path $repoRoot 'codex-overrides\wizard\template.ps1'),
  (Join-Path $repoRoot 'codex-overrides\diagnosing-bugs\scripts\hitl-loop.template.ps1')
)) {
  $tokens = $null
  $parseErrors = $null
  [Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$parseErrors) | Out-Null
  foreach ($parseError in @($parseErrors)) {
    $errors.Add("PowerShell语法错误 $scriptPath：$($parseError.Message)")
  }
}

if ($errors.Count -gt 0) {
  $errors | ForEach-Object { Write-Error $_ }
  throw "中文 Codex 技能验证失败，共 $($errors.Count) 项。"
}

Write-Host '中文 Codex 技能验证通过。'
Write-Host "正式技能：$($generated.Count)"
Write-Host "上游正式文件覆盖：$($sourceFiles.Count)"
Write-Host 'Windows与Bash模板：完整'
