#Requires -Version 7.0
Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName PresentationFramework

$running = Get-CimInstance Win32_Process |
Where-Object {
    $_.CommandLine -like "*work_timer.ps1*"
} |
Select-Object -First 1

if ($running) {

	. "$PSScriptRoot/global_vars.ps1"
	. "$parentDir/src/utils.ps1"
	. "$parentDir/json/state_func.ps1"

	$state = Load-State

	if (-not $state.cooldownUntil -and $state.extendedIdle) {
	Show-Balloon "Computer was idle for more than 10 minutes.`nReseting work session."
    Set-State $state    
	} elseif (-not $state.cooldownUntil -and (-not $state.warnedIdle)){
	Set-State $state
	}
}