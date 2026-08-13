function Set-State {
	$properties = Load-Properties
	$state = @{
		remainingSeconds = $properties.workPeriod
		thirdWarning = $false
		secondWarning = $false
		warnedoneMin = $false
		warnedIdle = $false
		extendedIdle = $false
		cooldown = $false
		cooldownUntil = $null
		lastTick = (Get-Now).ToString("o")
		eveningNotified = $false
		emergencyUsed = $false
		emergencyUntil = $null
		pomodoro = $properties.pomodoro
		pomNum = $properties.numPomodoros
		numPomodoros = $properties.numPomodoros
		startTime = $properties.startTime
		endTime = $properties.endTime
		days = $properties.days
		shortBreak = $properties.shortBreak
		lockOut = $properties.lockOut
		workPeriod = $properties.workPeriod
		lastUnlock = $null
		eveningLO = $properties.eveningLO
		duration = $properties.duration
		reminderPopups = $properties.reminderPopups
		sounds = $properties.sounds
		showPie = $properties.showPie
		showTime = $properties.showTime
		timeReminderChime = $properties.timeReminderChime
		workEndChime = $properties.workEndChime
		breakEndChime = $properties.breakEndChime
		mainProcessID = $mainPID
		volume = 500
		unlockReset = $false
		firstCountdown = $false
		scheduled = $properties.scheduled
		cycles = $properties.cycles
		numCycles = $properties.cycles
	}
	Save-State $state
}

function Reset-State{
	
	$state = Load-State
	$pomReset = $false
	
	$state.remainingSeconds = $state.workPeriod
	$state.thirdWarning = $false
	$state.secondWarning = $false
	$state.warnedoneMin = $false
	$state.warnedIdle = $false
	$state.extendedIdle = $false
	$state.cooldown = $false
	$state.cooldownUntil = $null
	$state.reset = $true
		
	if($state.pomNum -lt 1){
		$state.pomNum = $state.numPomodoros
		$pomReset = $true
	}
	Save-State $state
	return $pomReset
}
	

function Load-State {
    Get-Content $statePath -Raw | ConvertFrom-Json
}

function Save-State {
	param(
		$state
	)
    $state | ConvertTo-Json | Set-Content $statePath -Encoding UTF8
	return $(Load-State)
}

function Update-Pom {
	param(
		$state
	)
	$state.pomNum -= 1
	Save-State $state

	return $(Load-State)
}

function Update-Cycle {
	param(
		$state
	)
	$state.cycles -= 1
	Save-State $state

	return $(Load-State)
}