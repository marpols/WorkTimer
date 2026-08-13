$protocolPath = "HKCU:\Software\Classes\worktimer"
$ParentPath = Split-Path $PSScriptRoot

Write-Host $ParentPath

New-Item $protocolPath -Force | Out-Null
Set-ItemProperty $protocolPath -Name "(Default)" -Value "URL:WorkTimer"
Set-ItemProperty $protocolPath -Name "URL Protocol" -Value ""

New-Item "$protocolPath\shell\open\command" -Force | Out-Null

$handler = "C:\WorkTimer\protocol\WorkTimerProtocol.exe"

$command = "`"$handler`" `"%1`""

Set-Item `
    "HKCU:\Software\Classes\worktimer\shell\open\command" `
    -Value $command

