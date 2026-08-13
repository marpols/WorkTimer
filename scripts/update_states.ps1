#Requires -Version 7.0
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

$running = Get-CimInstance Win32_Process |
Where-Object {
    $_.CommandLine -like "*work_timer.ps1*"
} |
Select-Object -First 1

. "$PSScriptRoot/global_vars.ps1"
if (-not $parentDir) {
    throw "`$parentDir was not set by global_vars.ps1"
}
. "$PSScriptRoot/idle.ps1"

#load modules
$files = Get-childItem  -path $(Join-Path $parentDir "modules")
foreach ($file in $files.Name) {
    $path = Join-Path $parentDir "modules" $file
	if (-not (Test-Path $path)) {
        throw "Missing file: $path"
    }
	Import-Module $path
}

$state = Load-State
$inSchedule = ($state.scheduled -and (In-WorkHours))
$cyclesRemain = (-not ($state.cycles -le 1))


if ($running) {

	if ($inSchedule -or $cyclesRemain){
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
				$msg = "Computer was idle for more than 10 minutes. Timer has been reset.`n"
				Add-Content "$parentDir\logs\debug.log" "$now - Reset from unlock after extended idle"			
			} elseif (-not ($state.warnedIdle)){
				$state = Update-Pom $state

				$updated = Reset-State
				$state = Load-State
				
				if(-not $state.scheduled) {
					if ($state.pomodoro -and $updated){
						$state = Update-Cycle $state
					} elseif (-not $state.pomodoro){
						$state = Update-Cycle $state
					}	
				}

				$msg = $(if ($state.scheduled) { "" } else { "Session: $($state.numCycles - $state.cycles + 1) of $($state.numCycles)`n" })
				
				Add-Content "$parentDir\logs\debug.log" "$now - Reset from unlock"
			}

			if ($state.pomodoro){
				Pom-Message -state $state -msg $msg
			} else {
				Timer-Message -state $state -msg $msg
			}
		}

		$state.unlockReset = $true
		$state.lastUnlock = $now
		Save-State $state
	} else {
		#stop or pause cycles script
		#bring up popup to ask if user wants to continue
		#enact whatever selection they make
	}
}