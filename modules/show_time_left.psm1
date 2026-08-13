function Show-TimeLeft {
    $state = Load-State
  

    $pause = Get-PauseData

    $msg = ""

    if (-not $state.scheduled){
        $msg += "`nSet $($state.numCycles - $state.cycles + 1) of $($state.numCycles)"
    }

    $msg += "Time left: $(Get-RemainingText $state.remainingSeconds)"
	
	if ($state.pomodoro){
		$msg += "`nPomodoro:  $($state.numPomodoros - $state.pomNum + 1) out of $($state.numPomodoros)"
	}
	
    if ($pause) {
        $until = [datetime]$pause.pauseUntil
        $msg += "`nPause active until: $($until.ToString('HH:mm'))"
    }

    if ($state.cooldownUntil) {
        $cool = [datetime]$state.cooldownUntil
        if ((Get-Now) -lt $cool) {
            $msg += "`nBreak until: $($cool.ToString('HH:mm'))"
        }
    }
	
	if ($state.emergencyUsed) {
		$emergency = [datetime]$state.emergencyUntil
		if ((Get-Now) -lt $emergency) {
			$msg += "`nEmergency unlock applied until: $($emergency.ToString('HH:mm'))"
		}
	}
	
	if ($state.scheduled -and -not (In-WorkHours)){
		$msg = "Work Timer is running but not currently active."
	}

    if (-not $state.scheduled -and ($state.cycles -le 0)){
        $msg = "All sets completed!"
    }

    Show-Message $msg "Work Timer Status"
}