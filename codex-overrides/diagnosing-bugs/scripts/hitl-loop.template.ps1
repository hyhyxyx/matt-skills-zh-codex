[CmdletBinding()]
param()

# 人工参与的故障复现闭环模板。
# 复制本文件，修改下方步骤，然后在 PowerShell 中运行。
# 捕获观察结果，不要捕获密码、Token、Cookie 或完整认证头。

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Wait-HumanStep {
  param([Parameter(Mandatory)][string]$Instruction)
  Write-Host "`n>>> $Instruction"
  [void](Read-Host '    完成后按 Enter')
}

function Read-Observation {
  param([Parameter(Mandatory)][string]$Question)
  Write-Host "`n>>> $Question"
  return Read-Host '    >'
}

# 在这里编辑复现步骤。
Wait-HumanStep '打开 http://localhost:3000 并登录。'
$errored = Read-Observation '点击“导出”按钮后是否报错？(y/n)'
$errorMessage = Read-Observation '粘贴已经脱敏的错误信息；没有则输入 none。'

Write-Host "`n--- 已捕获 ---"
Write-Host "ERRORED=$errored"
Write-Host "ERROR_MSG=$errorMessage"
