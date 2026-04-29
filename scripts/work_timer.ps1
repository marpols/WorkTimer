#Requires -Version 7.0

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationFramework
[System.Windows.Forms.Application]::EnableVisualStyles()

. "$PSScriptRoot/global_vars.ps1"
if (-not $parentDir) {
    throw "`$parentDir was not set by global_vars.ps1"
}
. "$PSScriptRoot/idle.ps1"

$files = @("utils.psm1", "state_func.psm1", "pause_func.psm1","properties.psm1", "exit_challenge.psm1")
foreach ($file in $files) {
    $path = Join-Path $parentDir "modules" $file
	if (-not (Test-Path $path)) {
        throw "Missing file: $path"
    }
	Import-Module $path
}


$tbfrelock = 20000 #miliseconds (30s = 30000)


function Show-TimeLeft {
    $state = Load-State
  

    $pause = Get-PauseData
    $msg = "Time left in this Session: $(Get-RemainingText $state.remainingSeconds)"
	
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
	
	if (-not (In-WorkHours)){
		$msg = "Work Timer is running but not currently active."
	}

    Show-Message $msg "Work Timer Status"
}
$script:isExiting = $false

function Exit-App {
    if ($script:isExiting) {
        return
    }
	Start-Sleep -Milliseconds 150
    $passed = Show-ExitChallenge
    Add-Content "$parentDir\logs\debug.log" "Show-ExitChallenge returned: <$passed>"

    if (-not $passed) {
        Add-Content "$parentDir\logs\debug.log" "Exit cancelled"
        return
    }

    $script:isExiting = $true

    if ($script:timer) {
        $script:timer.Stop()
    }
    Cleanup-TrayIcon
    [System.Windows.Forms.Application]::Exit()
}

# Tray icon
$script:notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$script:notifyIcon.Icon = New-Object System.Drawing.Icon("$parentDir\assets\time.ico")
$script:notifyIcon.Text = "Work Timer"
$script:notifyIcon.Visible = $true

# Context menu
$menu = New-Object System.Windows.Forms.ContextMenuStrip

$itemShow = $menu.Items.Add("Show time left")
$itemPause = $menu.Items.Add("Pause for 1 hour")
$itemResume = $menu.Items.Add("End pause now")
$itemProperties = $menu.Items.Add("Properties")
$itemExit = $menu.Items.Add("Exit")

$itemShow.Add_Click({ Show-TimeLeft })
$itemPause.Add_Click({ Pause-OneHour })
$itemResume.Add_Click({ Resume-Now })
$itemProperties.Add_Click({ Show-Properties })
$itemExit.Add_Click({ 
	if (($state.eveningLO -and (In-EveningLockWindow)) -or ((Is-Scheduled) -and (In-WorkHours))){
		Exit-App 
	} else {
		if ($script:timer) {
        $script:timer.Stop()
		}
		Cleanup-TrayIcon
		[System.Windows.Forms.Application]::Exit()
	}
})

$itemEmergency = $menu.Items.Add("Emergency unlock (15 min)")
$itemEmergency.Add_Click({ powershell.exe -ExecutionPolicy Bypass -File "$parentDir\scripts\emergency_unlock.ps1" })

$script:notifyIcon.ContextMenuStrip = $menu
$script:notifyIcon.Add_DoubleClick({ Show-TimeLeft })

# Timer loop
$script:timer = New-Object System.Windows.Forms.Timer
$script:timer.Interval = $tbfrelock

$script:timer.Add_Tick({
    $state = Load-State
	
	$firstWarning = $state.workPeriod * 0.25
	if ($firstWarning -gt 1800){$firstWarning = 1800} elseif($firstWarning -lt 300){$firstWarning = 120} else{$firstWarning = [Math]::Ceiling($firstWarning/300)*300}
	$secondWarning = $state.workPeriod * 0.125
	if ($secondWarning -gt 900){$secondWarning = 900} elseif($firstWarning -eq 120){$secondWarning = 60} else{$secondWarning = [Math]::Ceiling($secondWarning/300)*300}
	if ($secondWarning -eq $firstWarning){$secondWarning = [Math]::Round($secondWarning)}
	$thirdWarning = $state.workPeriod * 0.0417
	if ($thirdWarning -gt 300){$thirdWarning = 300} elseif($secondWarning -eq 60){$thirdWarning = 30} else{$thirdWarning = [Math]::Ceiling($thirdWarning/300)*300}
	if ($thirdWarning -eq $secondWarning){$thirdWarning = [Math]::Round($thirdWarning)}

    $now = Get-Now
    $lastTick = [datetime]$state.lastTick
    $elapsed = [math]::Max(0, [int]($now - $lastTick).TotalSeconds)

	
	if ($state.emergencyUntil) {
		$emergencyUntil = [datetime]$state.emergencyUntil
		if ((Get-Date) -lt $emergencyUntil) {
			$state.lastTick = (Get-Date).ToString("o")
			Save-State $state
			return
		} else {
			$state.emergencyUntil = $null
		}
	}
	
	if ($state.eveningLO -and (In-EveningLockWindow)) {

		if (Pause-Active) {
			$state.lastTick = $now.ToString("o")
			Save-State $state
			return
		}
		
		if (-not $state.eveningNotified) {
			$endTime = Str-to-Date($state.endTime)
			Show-Message "Workday ended! You can come back at $($endTime.AddMinutes($state.duration).ToString('HH:mm')) if needed otherwise gtfo." "Work Timer"
			$state.eveningNotified = $true
			$state.lastTick = $now.ToString("o")
			Save-State $state
			}

		Lock-PC
		return
	}

    if (Pause-Active) {
        $state.lastTick = $now.ToString("o")
        Save-State $state
        return
    }
	
	if ($(Is-Idle 3) -and (-not $state.cooldown) -and (In-WorkHours)){
		if (-not $state.warnedIdle){
			Show-Balloon "Computer has been idle for 3 minutes. Pausing timer." "Work Timer"
			$state.warnedIdle = $true
		}
		if (Is-Idle 10){
			$state.extendedIdle = $true
		}
		$state.lastTick = $now.ToString("o")
		Save-State $state
		return
	} else {
		$state.warnedIdle = $false
	}

    if ($state.cooldownUntil) {
        $cooldownUntil = [datetime]$state.cooldownUntil
		$lastUnlock = [datetime]$state.lastUnlock
        if ($now -lt $cooldownUntil) {
            $state.lastTick = $now.ToString("o")
            Save-State $state
			Lock-PC
            return
        } else {
			if ($lastUnlock -ge $lastTick -or $lastUnlock -ge $cooldownUntil){
				Reset-State
				$state = Load-State
				$state.lastTick = $now.ToString("o")
				Save-State $state
				if ($state.pomodoro){
					Pom-Message $state
				} else {
					Timer-Message $state
				}
				Add-Content "$parentDir\logs\debug.log" "$now - Reset from work_timer.ps1 check"
				return
			}
            $state.cooldownUntil = $null
		}
    }
		
	
	if (-not (In-WorkHours)) {
        $state.lastTick = $now.ToString("o")
        Save-State $state
        return
    }

    $state.remainingSeconds -= $elapsed
    if ($state.remainingSeconds -lt 0) { $state.remainingSeconds = 0 }

    if (-not $state.warned30 -and $state.remainingSeconds -le $firstWarning -and $state.remainingSeconds -gt $secondWarning) {
        Show-Balloon "$(Get-RemainingText $state.remainingSeconds $true) left." "Work Timer"
        $state.warned30 = $true
    }

    if (-not $state.warned15 -and $state.remainingSeconds -le $secondWarning -and $state.remainingSeconds -gt $thirdWarning) {
        Show-Message "$(Get-RemainingText $state.remainingSeconds $true) left. Start wrapping up." "Work Timer"
        $state.warned15 = $true
    }
	
	if (-not $state.warned5 -and $state.remainingSeconds -le $thirdWarning -and $state.remainingSeconds -gt 0) {
		if ($thirdWarning -eq 30){
			$timetext = "30 seconds"
		} else {
			$timetext = "$(Get-RemainingText $state.remainingSeconds $true)"
		}
        Show-Message "$timetext left. Save your work now and write next steps." "Work Timer"
        $state.warned5 = $true
    }

    if (-not $state.cooldown -and $state.remainingSeconds -le 0) {
		if ($state.pomodoro){
			if($state.pomNum -gt 1){
				$text = "Short Break:"
				$lockoutTime = $state.shortBreak
			} else {
				$text = "Long Break:"
				$lockoutTime = $state.lockOut
			}
			$state.pomNum -= 1
		} else {
			$text = "Break:"
			$lockoutTime = $state.lockOut
		}
		$breakUntil = $now.AddMinutes($lockoutTime)
		Show-Popup "Time is up! The computer will lock now.`n$text $(Get-remainingText ($lockoutTime*60) $true)`nYou can come back at $($breakUntil.ToString(`"HH:mm`"))" "Work Timer"	
        $state.cooldownUntil = $breakUntil.ToString("o")
		$state.cooldown = $true
        Lock-PC
    }

    $state.lastTick = $now.ToString("o")
    Save-State $state
})
if (-not (Test-Path $propertiesPath)){
	Default-Properties
}

$properties = Load-Properties

# Start
Set-State
if (-not (In-WorkHours)){
	$msg = "Work Timer is running but not active.`nActive $($properties.days | ForEach-Object { $_[0] }), $($properties.startTime)-$($properties.endTime).`nGo to properties to update schedule." 
} else {
	if ($properties.pomodoro){
		$msg = "Work Timer is running`nActive $($properties.days | ForEach-Object { $_[0] }), $($properties.startTime)-$($properties.endTime)`nNumber of Pomodoros: $($properties.numPomodoros)`nWork for: $(Get-RemainingText $properties.workPeriod $true)`nShort breaks for: $($properties.shortBreak) minute(s)`nLong breaks for: $($properties.lockOut) minutes."
	} else {
		$msg = "Work Timer is running`nActive $($properties.days | ForEach-Object { $_[0] }), $($properties.startTime)-$($properties.endTime)`nWork for: $(Get-RemainingText $properties.workPeriod $true) `nBreaks for: $($properties.lockOut) minutes"
	}
	if ($properties.eveningLO){
		$msg += "`nEvening Lockout enabled for $($properties.duration) minutes"
	}
}

Show-Balloon $msg 
$script:timer.Start()

[System.Windows.Forms.Application]::Run()