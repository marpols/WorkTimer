#Requires -Version 7.0

$mutexName = 'Work Timer'

$createdNew = $false

$script:mutex = [System.Threading.Mutex]::new(
    $true,
    $mutexName,
    [ref]$createdNew
)

$script:exitEvent = [System.Threading.EventWaitHandle]::new(
    $false,
    [System.Threading.EventResetMode]::AutoReset,
    "WorkTimerExit"
)

$script:startCyclesEvent =
    [System.Threading.EventWaitHandle]::new(
        $false,
        [System.Threading.EventResetMode]::AutoReset,
        "WorkTimerStartCycles"
    )

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

if (-not $createdNew) {
    Toast-Notification -msg "Work Timer is already running."
	Exit-App $false
    exit
}

$tbfrelock = 20000 #miliseconds (30s = 30000)
$mainPID = $PID

$script:isExiting = $false

# Tray icon
$script:notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$script:notifyIcon.Icon = New-Object System.Drawing.Icon("$parentDir\assets\time.ico")
$script:notifyIcon.Text = "Work Timer"
$script:notifyIcon.Visible = $true

# Context menu
$menu = New-Object System.Windows.Forms.ContextMenuStrip

$itemShow = $menu.Items.Add("Show time left")
$itemRestart =$menu.Items.Add("Start new Session...")
$itemPause = $menu.Items.Add("Pause for 1 hour")
$itemResume = $menu.Items.Add("End pause now")
$itemEmergency = $menu.Items.Add("Emergency unlock (15 min)")
$itemProperties = $menu.Items.Add("Properties")
$itemExit = $menu.Items.Add("Exit")

$menu.Add_Opening({
    param($sender, $e)

	Update-ContextMenu `
	 -menu $sender `
	 -state $(Load-State)

})

$itemShow.Add_Click({ Show-TimeLeft })
$itemRestart.Add_Click({set-cycles})
$itemPause.Add_Click({ Pause-OneHour })
$itemResume.Add_Click({ Resume-Now })
$itemProperties.Add_Click({ Show-Properties })


$itemExit.Add_Click({ 

	Exit-App $true

})


$itemEmergency.Add_Click({ powershell.exe -ExecutionPolicy Bypass -File "$parentDir\scripts\emergency_unlock.ps1" })

# $contextMenu.Add_Opening({
#     param($sender, $e)

#     $state = Load-State

#     Update-ContextMenu `
#         -State $state `
# })

$script:notifyIcon.ContextMenuStrip = $menu
$script:notifyIcon.Add_DoubleClick({ Show-TimeLeft })

$script:controlTimer = New-Object System.Windows.Forms.Timer
$script:controlTimer.Interval = 250

$script:controlTimer.Add_Tick({

    if ($script:exitEvent.WaitOne(0)) {
        Exit-App -exitChallenge $false
        return
    }

    if ($script:startCyclesEvent.WaitOne(0)) {
        Start-CyclesScript
        return
    }
})

$script:controlTimer.Start()


if (-not (Test-Path $propertiesPath)){
	Default-Properties
}
$properties = Load-Properties

# Start
Set-State

if ($properties.scheduled){
	if (-not (In-WorkHours)){
		$msg = "but not active.`nActive $($properties.days | ForEach-Object { $_[0] }), $($properties.startTime)-$($properties.endTime).`nGo to properties to update schedule." 
	} else {
		if ($properties.pomodoro){
			$msg = "Active $($properties.days | ForEach-Object { $_[0] }), $($properties.startTime)-$($properties.endTime)`nPomodoros: $($properties.numPomodoros)`nWork for: $(Get-RemainingText $properties.workPeriod $true), Breaks for: $($properties.shortBreak) minute(s)`nLong breaks: $($properties.lockOut) minutes."
			$msg2 = "Pomodoro 1 of $($properties.numPomodoros)"
		} else {
			$msg = "Active $($properties.days | ForEach-Object { $_[0] }), $($properties.startTime)-$($properties.endTime)`nWork for: $(Get-RemainingText $properties.workPeriod $true), Breaks for: $($properties.lockOut) minute(s)"
			$msg2 = ""
		}	
		if ($properties.eveningLO){
			$msg += "`nEvening Lockout enabled for $($properties.duration) minutes"
		}
	}
	Toast-Notification -header "Work Timer is in Schedule Mode" -msg $msg
	Start-TimerScript
} else {
	Cycles-notification -msg "Work Timer will run for $($properties.cycles) set(s)"
}


$showCountdownHandler = {
    [System.Windows.Forms.Application]::remove_Idle(
        $script:showCountdownHandler
    )
	$state = Load-State
    if ($properties.showPie -or $properties.showTime -and (In-WorkHours)) {
        $script:pieCountdown = Show-CountdownPie `
            -DurationSeconds $properties.workPeriod `
			-workPeriod $properties.workPeriod `
            -showPie $properties.showPie `
            -showTime $properties.showTime `
			-mainPID $mainPID
		$state.firstCountdown = $true
    } else {
		$state.firstCountdown = $false
	}
	Save-State $state
}

$script:showCountdownHandler = $showCountdownHandler
[System.Windows.Forms.Application]::add_Idle(
    $script:showCountdownHandler
)

[System.Windows.Forms.Application]::Run()

