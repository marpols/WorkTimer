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
	}
	Save-State $state
}

function Reset-State{
	
	$state = Load-State
	
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
	}
	Save-State $state
}
	

function Load-State {
    Get-Content $statePath -Raw | ConvertFrom-Json
}

function Save-State($state) {
    $state | ConvertTo-Json | Set-Content $statePath -Encoding UTF8
}

function Update-Pom($state) {
	$state.pomNum -= 1
	Save-State $state
	Load-State
}