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

#load modules
$files = Get-childItem  -path $(Join-Path $parentDir "modules")
foreach ($file in $files.Name) {
    $path = Join-Path $parentDir "modules" $file
	if (-not (Test-Path $path)) {
        throw "Missing file: $path"
    }
	Import-Module $path
}

$tbfrelock = 20000 #miliseconds (30s = 30000)

$script:isExiting = $false

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
	if (($state.eveningLO -and (In-EveningLockWindow)) -or (In-WorkHours)){
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

    $now = Get-Now
    $lastTick = [datetime]$state.lastTick
    $elapsed = [math]::Max(0, [int]($now - $lastTick).TotalSeconds)

	#check if emergency unlock
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
	
	#check if in evening lockout (if activated)
	if ($state.eveningLO -and (In-EveningLockWindow)) {

		if (Pause-Active) {
			$state.lastTick = $now.ToString("o")
			Save-State $state
			return
		}
		
		if (-not $state.eveningNotified) {
			$endTime = Str-to-Date($state.endTime)
			Show-Popup -text "Workday ended! You can come back at $($endTime.AddMinutes($state.duration).ToString('HH:mm')) if needed otherwise gtfo." - title "Work Timer"
			$state.eveningNotified = $true
			$state.lastTick = $now.ToString("o")
			Save-State $state
			}

		Lock-PC
		return
	}

	#check pause active
    if (Pause-Active) {
        $state.lastTick = $now.ToString("o")
        Save-State $state
        return
    }
	
	#check idle
	if ($(Is-Idle 3) -and (-not $state.cooldown) -and (In-WorkHours)){
		if (-not $state.warnedIdle){
			Toast-Notification -msg "Computer has been idle for 3 minutes. Pausing timer." -header "Work Timer"
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

	#in cooldown/break
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
				Update-Pom $state
				Reset-State
				$state = Load-State
				$state.lastTick = $now.ToString("o")
				Save-State $state
				if ($state.pomodoro){
					$timer_msg = Pom-Message $state
				} else {
					Timer-Message $state
					$timer_msg = ""
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

	#reminders
	$reminderChime = "$parentDir\assets\sounds\long-chime-sound.mp3"
    $state.remainingSeconds -= $elapsed
	if ($state.remainingSeconds -lt 0) { $state.remainingSeconds = 0 }

	$warnings = Time_Warning($state.workPeriod)
	$oneminWarning = -not $state.warnedoneMin -and $state.remainingSeconds -le 60 -and $state.remainingSeconds -gt 0
	$secondPopup = -not $state.secondWarning -and $state.remainingSeconds -le $warnings.second -and $state.remainingSeconds -gt 60
	$thirdPopup = -not $state.thirdWarning -and $state.remainingSeconds -le $warnings.third -and $state.remainingSeconds -gt $warnings.second
	

    if ($thirdPopup) {
        Toast-Notification "$(Get-RemainingText $state.remainingSeconds $true) left."
        $state.thirdWarning = $true
    }

    if ($secondPopup) {
        Show-Popup -text "$(Get-RemainingText $state.remainingSeconds $true) left.`nStart wrapping up." -soundfile $reminderChime
        $state.secondWarning = $true
    }
	
	#1 minute warning
	if ($oneminWarning) {

		#start toast notification as seperate process
		Start-Countdown -duration 1 -chime $false -msg "1 minute to go!" -msg2 "Save your work and write next steps (leave some breadcrumbs)" -barTitle "Time until break:" -endMsg "You did it! Time for a break!"

		Show-Popup -text "1 minute left!" -soundfile $reminderChime
        $state.warnedoneMin = $true
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
		} else {
			$text = "Break:"
			$lockoutTime = $state.lockOut
		}
		$breakUntil = $now.AddMinutes($lockoutTime)
		Show-Popup -text "Time is up! The computer will lock now.`n$text $(Get-remainingText ($lockoutTime*60) $true)`nYou can come back at $($breakUntil.ToString(`"HH:mm`"))"	
        $state.cooldownUntil = $breakUntil.ToString("o")
		$state.cooldown = $true
        Lock-PC
		
		$endChime = "$parentDir\assets\sounds\alarm-bell.mp3"
		
		Start-Countdown -duration $lockoutTime -imageFile "C:\WorkTimer\assets\break_time-amonrat-rungreangfangsai.png"
		
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

# pop-up message
if (-not (In-WorkHours)){
	$msg = "but not active.`nActive $($properties.days | ForEach-Object { $_[0] }), $($properties.startTime)-$($properties.endTime).`nGo to properties to update schedule." 
} else {
	if ($properties.pomodoro){
		$msg = "Active $($properties.days | ForEach-Object { $_[0] }), $($properties.startTime)-$($properties.endTime)`nNumber of Pomodoros: $($properties.numPomodoros)`nWork for: $(Get-RemainingText $properties.workPeriod $true)`nShort breaks for: $($properties.shortBreak) minute(s)`nLong breaks for: $($properties.lockOut) minutes."
		$msg2 = "Pomodoro 1 of $($properties.numPomodoros)"
	} else {
		$msg = "Active $($properties.days | ForEach-Object { $_[0] }), $($properties.startTime)-$($properties.endTime)`nWork for: $(Get-RemainingText $properties.workPeriod $true) `nBreaks for: $($properties.lockOut) minute(s)"
	    $msg2 = ""
	}	
	if ($properties.eveningLO){
		$msg += "`nEvening Lockout enabled for $($properties.duration) minutes"
	}
}

Toast-Notification -header "Work Timer is running" -msg $msg
#Start-Countdown -duration $($properties.workPeriod/60) -chime $false -noPopup $true -msg "Time to focus!" -msg2 $msg2 -barTitle "Time remaining:" -endMsg "Time for a break!"  -imageFile "C:\WorkTimer\assets\freelance_amonrat-rungreangfangsai.png" -removeAfter 300

$script:timer.Start()
[System.Windows.Forms.Application]::Run()