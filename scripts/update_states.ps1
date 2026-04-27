#Requires -Version 7.0
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

$running = Get-CimInstance Win32_Process |
Where-Object {
    $_.CommandLine -like "*work_timer.ps1*"
} |
Select-Object -First 1



if ($running) {
	
	. "$PSScriptRoot\global_vars.ps1"
	Import-Module "$parentDir/modules/utils.psm1" -Function "Get-Now", "Show-Balloon", "Show-Popup", "Get-RemainingText", "Pom-Message", "Timer-Message"
	Import-Module "$parentDir/modules/state_func.psm1" -Function "Load-State", "Save-State", "Reset-State"
	Import-Module "$parentDir/modules/properties.psm1" -Function "Load-Properties"
	

	$state = Load-State
	$now = Get-Now
	if ($state.cooldownUntil){$cooldown = [datetime]$state.cooldownUntil} else {$cooldown = 0} 
	$timeLeft = [math]::Max(0,$($cooldown- $now).TotalSeconds)

	if ($state.cooldownUntil){
		if ($timeLeft -gt 20){
			Show-Popup "Break Time!`nYou can come back in $(Get-RemainingText $timeLeft $true)" "Work Timer" -chime $false
		}
	} elseif (-not $state.cooldownUntil -and $state.extendedIdle) {
		Reset-State
		$state = Load-State
		Show-Balloon "Computer was idle for more than 10 minutes. Time has been reset.`n"		
	} elseif (-not $state.cooldownUntil -and (-not $state.warnedIdle)){
		Reset-State
		$state = Load-State
		if ($state.pomodoro){
			Pom-Message $state
		} else {
			Timer-Message $state
		}
		Add-Content "$parentDir\logs\debug.log" "$now - Reset from unlock"
	}
	$state = Load-State
	$state.lastUnlock = $now
	Save-State $state
}