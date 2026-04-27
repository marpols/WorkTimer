function Set-State {
	$properties = Load-Properties
	$state = @{
		remainingSeconds = $properties.workPeriod
		warned30 = $false
		warned15 = $false
		warned5 = $false
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
		
	}
	Save-State $state
}

function Reset-State{
	$properties = Load-Properties
	$state = Load-State
	
	$state.remainingSeconds = $state.workPeriod
	$state.warned30 = $false
	$state.warned15 = $false
	$state.warned5 = $false
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