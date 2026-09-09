[CmdletBinding()]
param(
  [string]$EnvFile = '.env'
)

# 中文 Codex 的 Windows 原生交互式配置向导模板。
# 保留阶段、人工确认、环境变量写入和 GitHub Secrets 能力。

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$script:TotalStages = 1
$script:StageIndex = 0
$script:WrittenEnv = [Collections.Generic.List[string]]::new()
$script:WrittenSecrets = [Collections.Generic.List[string]]::new()
$script:Skipped = [Collections.Generic.List[string]]::new()

function Show-Banner {
  param([Parameter(Mandatory)][string]$Title)
  Clear-Host
  Write-Host "`n  $Title" -ForegroundColor Cyan
  Write-Host "  共 $script:TotalStages 个阶段" -ForegroundColor DarkGray
  Write-Host '  你操作浏览器，本向导提供步骤并保存你复制回来的值。'
  Write-Host '  随时可以按 Ctrl+C 停止；已经写入的值会在下次运行时复用。' -ForegroundColor DarkGray
  [void](Read-Host '  准备好后按 Enter')
}

function Start-WizardStage {
  param([Parameter(Mandatory)][string]$Name)
  Clear-Host
  $script:StageIndex++
  Write-Host "`n  阶段 $script:StageIndex/$script:TotalStages · $Name" -ForegroundColor Cyan
}

function Write-Step {
  param([Parameter(Mandatory)][string]$Text)
  Write-Host "  • $Text" -ForegroundColor Cyan
}

function Write-Note {
  param([Parameter(Mandatory)][string]$Text)
  Write-Host "  $Text" -ForegroundColor DarkGray
}

function Write-WarningNote {
  param([Parameter(Mandatory)][string]$Text)
  Write-Host "  ⚠ $Text" -ForegroundColor Yellow
}

function Open-WizardUrl {
  param([Parameter(Mandatory)][ValidatePattern('^https?://')][string]$Url)
  Write-Host "  ↗ 正在打开 $Url" -ForegroundColor Green
  try {
    Start-Process -FilePath $Url | Out-Null
  } catch {
    Write-WarningNote "无法自动打开浏览器，请手动访问：$Url"
  }
}

function Confirm-WizardAction {
  param([Parameter(Mandatory)][string]$Question)
  $reply = Read-Host "  ? $Question [y/N]"
  return $reply -match '^[Yy]$'
}

function Get-ExistingEnvValue {
  param([Parameter(Mandatory)][string]$Key)
  if (-not (Test-Path -LiteralPath $EnvFile -PathType Leaf)) {
    return $null
  }
  $prefix = "$Key="
  $line = Get-Content -LiteralPath $EnvFile |
    Where-Object { $_.StartsWith($prefix, [StringComparison]::Ordinal) } |
    Select-Object -Last 1
  if ($null -eq $line) {
    return $null
  }
  return $line.Substring($prefix.Length)
}

function Read-WizardValue {
  param(
    [Parameter(Mandatory)][string]$Key,
    [Parameter(Mandatory)][string]$Prompt
  )
  $current = Get-ExistingEnvValue -Key $Key
  $suffix = if ([string]::IsNullOrEmpty($current)) { '' } else { '（直接回车保留当前值）' }
  $value = Read-Host "  $Prompt$suffix"
  if ([string]::IsNullOrEmpty($value) -and -not [string]::IsNullOrEmpty($current)) {
    return $current
  }
  return $value
}

function Read-WizardSecret {
  param(
    [Parameter(Mandatory)][string]$Key,
    [Parameter(Mandatory)][string]$Prompt
  )
  $current = Get-ExistingEnvValue -Key $Key
  $suffix = if ([string]::IsNullOrEmpty($current)) { '' } else { '（直接回车保留当前值）' }
  $secure = Read-Host "  $Prompt$suffix" -AsSecureString
  $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
  try {
    $value = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)
  } finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer)
  }
  if ([string]::IsNullOrEmpty($value) -and -not [string]::IsNullOrEmpty($current)) {
    return $current
  }
  return $value
}

function Set-EnvValue {
  param(
    [Parameter(Mandatory)][string]$Key,
    [Parameter(Mandatory)][AllowEmptyString()][string]$Value
  )
  $lines = if (Test-Path -LiteralPath $EnvFile -PathType Leaf) {
    @(Get-Content -LiteralPath $EnvFile)
  } else {
    @()
  }
  $prefix = "$Key="
  $remaining = @($lines | Where-Object { -not $_.StartsWith($prefix, [StringComparison]::Ordinal) })
  @($remaining + "$Key=$Value") | Set-Content -LiteralPath $EnvFile -Encoding utf8
  $script:WrittenEnv.Add($Key)
  Write-Host "  ✓ 已写入 $Key → $EnvFile" -ForegroundColor Green
}

function Test-GitHubCli {
  if ($null -eq (Get-Command gh -ErrorAction SilentlyContinue)) {
    return $false
  }
  & gh auth status *> $null
  return $LASTEXITCODE -eq 0
}

function Set-GitHubSecret {
  param(
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][AllowEmptyString()][string]$Value
  )
  if (Test-GitHubCli) {
    $Value | & gh secret set $Name *> $null
    if ($LASTEXITCODE -eq 0) {
      $script:WrittenSecrets.Add($Name)
      Write-Host "  ✓ 已设置 GitHub Secret：$Name" -ForegroundColor Green
      return
    }
  }
  $script:Skipped.Add("GitHub Secret $Name（稍后运行 gh secret set $Name）")
  Write-WarningNote "没有设置 GitHub Secret $Name；请确认 gh 已登录后重试。"
}

function Set-GitHubVariable {
  param(
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][AllowEmptyString()][string]$Value
  )
  if (Test-GitHubCli) {
    & gh variable set $Name --body $Value *> $null
    if ($LASTEXITCODE -eq 0) {
      Write-Host "  ✓ 已设置 GitHub Variable：$Name" -ForegroundColor Green
      return
    }
  }
  $script:Skipped.Add("GitHub Variable $Name")
  Write-WarningNote "没有设置 GitHub Variable $Name；请确认 gh 已登录后重试。"
}

function Complete-Wizard {
  Clear-Host
  Write-Host "`n  ✓ 配置完成" -ForegroundColor Green
  if ($script:WrittenEnv.Count -gt 0) {
    Write-Note "已向 $EnvFile 写入 $($script:WrittenEnv.Count) 个值：$($script:WrittenEnv -join ', ')"
  }
  if ($script:WrittenSecrets.Count -gt 0) {
    Write-Note "已设置 $($script:WrittenSecrets.Count) 个 GitHub Secret：$($script:WrittenSecrets -join ', ')"
  }
  if ($script:Skipped.Count -gt 0) {
    Write-WarningNote '仍需手动处理：'
    foreach ($item in $script:Skipped) {
      Write-Note "- $item"
    }
  }
}

# 在这里替换示例阶段，并让 TotalStages 与阶段数量一致。
Show-Banner -Title 'Stripe 配置'
Start-WizardStage -Name 'Stripe API 密钥'
Open-WizardUrl -Url 'https://dashboard.stripe.com/test/apikeys'
Write-Step '复制 Publishable key，通常以 pk_test_ 开头。'
$publishableKey = Read-WizardValue -Key 'STRIPE_PUBLISHABLE_KEY' -Prompt '粘贴 Publishable key：'
Write-Step '点击 Secret key 所在行的 Reveal test key，然后复制。'
$secretKey = Read-WizardSecret -Key 'STRIPE_SECRET_KEY' -Prompt '粘贴 Secret key：'

if (Confirm-WizardAction '确认把以上值写入本地环境文件，并把 Secret key 设置到当前 GitHub 仓库吗？') {
  Set-EnvValue -Key 'STRIPE_PUBLISHABLE_KEY' -Value $publishableKey
  Set-EnvValue -Key 'STRIPE_SECRET_KEY' -Value $secretKey
  Set-GitHubSecret -Name 'STRIPE_SECRET_KEY' -Value $secretKey
} else {
  $script:Skipped.Add('本地环境变量和 GitHub Secret（用户未确认写入）')
}

Complete-Wizard
