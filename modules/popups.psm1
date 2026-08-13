function Show-Message($text, $title = "Work Timer", $type = 'Warning') {
   [System.Windows.Forms.MessageBox]::Show(
    $text,
    $title,
    [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Warning,
	[System.Windows.Forms.MessageBoxDefaultButton]::Button1,
	[System.Windows.Forms.MessageBoxOptions]::ServiceNotification
	)
}

function Show-Balloon($text, $title = "Work Timer", $timeout = 5000) {
	$balloon = New-Object System.Windows.Forms.NotifyIcon
	$path = (Get-Process -Id $pid).Path
	$balloon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($path)
	$balloon.BalloonTipTitle = $title
	$balloon.BalloonTipText = $text
	$balloon.Visible = $true
	$balloon.ShowBalloonTip($timeout)
	$balloon.Dispose()
}

function Show-Popup {
	param(
		[string]$text,
		[string]$title = "Work Timer",
		[int]$timeout = 5000,
		$chime = $true,
		[string]$soundfile = "$parentDir\assets\sounds\long-chime-sound.mp3",
		$volume = 500
		)

	Add-Type -AssemblyName System.Windows.Forms
	Add-Type -AssemblyName System.Drawing

	$screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
	$screenWidth = $screen.Width
	$screenHeight = $screen.Height

	$popupSize = [System.Drawing.Size]::new(
    [int]($screenWidth / 3),
    [int]($screenHeight / 3)
	)

	$icon = New-Object System.Drawing.Icon("C:\WorkTimer\assets\time.ico")
	$form = New-Object System.Windows.Forms.Form -Property @{Text = $title; Size = $popupSize; StartPosition = "CenterScreen"; TopMost = $true; Icon = $icon}

	$fontSize = [Math]::Max(
        10,
        [int]([Math]::Min($form.ClientSize.Width, $form.ClientSize.Height) / 10)
    )

	$label = New-Object System.Windows.Forms.Label -Property @{Text = $text; Dock = "Fill"; TextAlign = "MiddleCenter"; Font = "Segoe UI, $($fontsize)" }

	$form.Controls.Add($label)

	$timer = New-Object System.Windows.Forms.Timer
	$timer.Interval = $timeout
	$timer.Add_Tick({
		$timer.Stop()
		$form.Close()
	}.GetNewClosure())

	$form.Add_Shown({
		$timer.Start()
	}.GetNewClosure())

	if($chime){
		Play-Chime -soundfile $soundfile -volume $volume
	}
	
	[void]$form.ShowDialog()
	
    $timer.Dispose()
    $form.Dispose()
    $icon.Dispose()
}

function Pom-Message {
	param(
		$state,
		[string]$msg = ""
	)
	$msg += "🍅 Pomodoro:  $($state.numPomodoros - $state.pomNum + 1) out of $($state.numPomodoros)" 
	Toast-Notification -msg $msg -header "Work Timer is Active"
	return($msg)
}

function Timer-Message {
	param(
		$state,
		[string]$msg = ""
	)
	$msg += "⏲️ Work Time: $(Get-RemainingText $state.workPeriod $true)`n Breaks: $(Get-RemainingText $($state.lockOut*60) $true)" 
	Toast-Notification -msg $msg -header "Work Timer is Active" 
}