#Requires -Version 7.0
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

$running = Get-CimInstance Win32_Process |
Where-Object {
    $_.CommandLine -like "*work_timer.ps1*"
} |
Select-Object -First 1

. "$PSScriptRoot\global_vars.ps1"
Import-Module "$parentDir/modules/utils.psm1" -Function "Get-Now", "Show-Balloon", "Show-Popup", "Get-RemainingText", "Pom-Message", "Timer-Message", "In-WorkHours"
Import-Module "$parentDir/modules/state_func.psm1" -Function "Load-State", "Save-State", "Reset-State", "Update-Pom"
Import-Module "$parentDir/modules/properties.psm1" -Function "Load-Properties"

if ($running -and (In-WorkHours)) {

	$state = Load-State
	$now = Get-Now
	if ($state.cooldownUntil){$cooldown = [datetime]$state.cooldownUntil} else {$cooldown = 0} 
	$timeLeft = [math]::Max(0,$($cooldown- $now).TotalSeconds)

	if ($state.cooldownUntil){
		if ($timeLeft -gt 20){
			Show-Popup "Break Time!`nYou can come back in $(Get-RemainingText $timeLeft $true)" "Work Timer" -chime $false
		}
	} else {
		if ($state.extendedIdle) {
			Reset-State
			$state = Load-State
			$msg = "Computer was idle for more than 10 minutes. Time has been reset.`n"
			Add-Content "$parentDir\logs\debug.log" "$now - Reset from unlock after extended idle"			
		} elseif (-not ($state.warnedIdle)){
			$state = Update-Pom $state
			Reset-State
			$state = Load-State
			$msg = ""
			Add-Content "$parentDir\logs\debug.log" "$now - Reset from unlock"
		}
		if ($state.pomodoro){
			Pom-Message $state $msg
		} else {
			Timer-Message $state
		}
		
	}

	$state.lastUnlock = $now
	Save-State $state
}