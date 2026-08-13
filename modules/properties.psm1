function Show-Properties {
	Add-Type -AssemblyName System.Drawing
	Add-Type -AssemblyName System.Windows.Forms
	
	$parentDir = Split-Path -Path $PSScriptRoot -Parent
	$properties = Load-Properties
	
	$form = New-Object System.Windows.Forms.Form -Property @{
		Text = "Work Timer Properties";
		ClientSize = [System.Drawing.Size]::new(480, 370);
		StartPosition = "CenterScreen";
		AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None
		Icon = New-Object System.Drawing.Icon("$parentDir\assets\time.ico")
	}

	$tabControl = New-Object System.Windows.Forms.TabControl -Property @{
		Dock = "Top";
		Size = '480,300'
	}
	
	$modePage = New-Object System.Windows.Forms.TabPage -Property @{Text = "Timer Mode"}
	$setPage = New-Object System.Windows.Forms.TabPage -Property @{Text = "Settings"}
	$schedPage = New-Object System.Windows.Forms.TabPage -Property @{Text = "Schedule"}
	$diffPage = New-Object System.Windows.Forms.TabPage -Property @{Text = "Exit Difficulty"}
	$remPage = New-Object System.Windows.Forms.TabPage -Property @{Text = "Reminders"}
	$dispPage = New-Object System.Windows.Forms.TabPage -Property @{Text = "Countdown Display"}

	$tabOrder = @(
    	$modePage
    	$setPage
    	$schedPage
    	$diffPage
    	$remPage
		$dispPage
	)
	
	$tabControl.Controls.AddRange($tabOrder)
	$form.Controls.Add($tabControl)

	####### Mode Tab
	$modeOpts = toggle-schedule -page $modePage -properties $properties
	if($modeOpts.session.Checked){$tabControl.Controls.Remove($schedPage)}

	####### Settings Tab
	#Work Period
	$workOpts = work-Options -page $setPage -properties $properties

	#Lockout
	$LOopts = lockout-Options -page $setPage -properties $properties

	#Pomodoro Mode
	$pomOpts = pomodoro-Options -page $setPage -properties $properties -objLO $LOopts.LO
	
	if($pomOpts.check.Checked){
		Set-ControlsVisible $true $pomOpts.controls
		Set-ControlsVisible $false $LOopts.controls
	} else {
		Set-ControlsVisible $false $pomOpts.controls
		Set-ControlsVisible $true $LOopts.controls
	}
	$pomOpts.check.Add_CheckedChanged({
		  if ($pomOpts.check.Checked) {
			Set-ControlsVisible $true $pomOpts.controls
			Set-ControlsVisible $false $LOopts.controls
		} else {
			Set-ControlsVisible $false $pomOpts.controls
			Set-ControlsVisible $true $LOopts.controls
		}
	})
	
	#Evening Lockout
	$ELOopts = ELO-Options -page $setPage -properties $properties
	
	$modeOpts.schedule.Add_CheckedChanged({
		Set-TabVisible $tabControl $tabOrder $modeOpts.schedule.Checked $schedPage
		Set-ControlsEnabled $modeOpts.schedule.Checked @($ELOopts.all_controls)
	})

	$verticalLine = New-Object System.Windows.Forms.Panel -Property @{Width=1; Height=200; Left=275; Top=20; BorderStyle="Fixed3D"; BackColor = [System.Drawing.Color]::Gray}
	$setPage.Controls.Add($verticalLine)

	####### Schedule Tab
	#Days of the Week

	$dayOpts = day-Options -page $schedPage -properties $properties

	#Timeframe
	$timeOpts = time-Options -page $schedPage -mainform $form -properties $properties


	####### Exit Diffculty Tab
	#Exit Difficulty Slider
	$diffOpts = diff-options -page $diffPage -properties $properties

	####### Reminders Tab
	$remOpts = reminder-options -page $remPage -properties $properties

	#sound options
	## volume
	$volOpts = volume-options -page $remPage -properties $properties

	$soundFiles  = Get-ChildItem -Path "$parentdir/assets/sounds" -File 
	foreach ($row in $soundFiles) {
    	$cleanName = "$($row.Name -replace '-', ' ' -replace '\.mp3$', '')"
    	$row | Add-Member -MemberType NoteProperty -Name "CleanName" -Value $cleanName
	}
	$soundFiles = $soundFiles | Sort-Object CleanName
	
	## time left
	$timeRemOpts = timeRem-Options -page $remPage -properties $properties -sounds $soundFiles -volume ($volOpts.volume)

	# #end of work session
	$workRemOpts = workRem-Options -page $remPage -properties $properties -sounds $soundFiles -volume ($volOpts.volume)

	# #end of break period
	$breakRemOpts = breakRem-Options -page $remPage -properties $properties -sounds $soundFiles -volume ($volOpts.volume)

	$controlsSound = ($volOpts.controls + $timeRemOpts.controls + $workRemOpts.controls + $breakRemOpts.controls)

	if($remOpts.sounds.Checked){
		Set-ControlsEnabled $true $controlsSound
	} else {
		Set-ControlsEnabled $false $controlsSound
	}
	$remOpts.sounds.Add_CheckedChanged({
		  if ($remOpts.sounds.Checked) {
			Set-ControlsEnabled $true $controlsSound
		} else {
			Set-ControlsEnabled $false $controlsSound
		}
	})

	####### Style
	$dispOpts = display-options -page $dispPage -properties $properties
	
	####### Bottom of properties form
	#Update All Button
	$updateAll = New-Object System.Windows.Forms.Button -Property @{Location='247,310'; Size='100,40'; Text="Save"}
	$updateAll.Add_Click({
		$properties.scheduled = $modeOpts.schedule.Checked
		$properties.cycles = $modeOpts.cycles.Value

		$time = HM-S $workOpts.hours.Value $workOpts.min.Value
		$properties.workPeriod = $time
		$properties.lockOut = $LOopts.value.Value
		$properties.pomodoro = $pomOpts.check.Checked
		if($pomOpts.check.Checked){
					$properties.shortBreak = $pomOpts.shortBreak.Value
					$properties.numPomodoros = $pomOpts.pomNum.Value
		}
		$properties.days = @($dayOpts.list.CheckedItems | ForEach-Object { $_.ToString() })
		if(Check-Hours $timeOpts.start.Value $timeOpts.end.Value $form){
			$form.Refresh()
			$form.Activate()
		} else {
			$properties.startTime = $timeOpts.start.Value.ToString("HH:mm")
			$properties.endTime = $timeOpts.end.Value.ToString("HH:mm")
		}
		$properties.eveningLO = $ELOopts.check.Checked
		$properties.duration = $ELOopts.value.Value
		
		$properties.exitDifficulty = $diffOpts.value.Value

		$properties.reminderPopups = $remOpts.popups.Checked
		$properties.sounds = $remOpts.sounds.Checked

		$properties.volume = $volOpts.volume.Value * 10

		$properties.showPie = $dispOpts.vals.showPie
		$properties.showTime = $dispOpts.vals.showTime
		$properties.pieChartClr = $dispOpts.vals.pieClr
		$properties.textDispClr = $dispOpts.vals.txtClr

		Save-Properties -properties $properties
		Toast-Notification -msg "All settings have been updated.`nChanges will take effect on restart." -header "Work Timer Update"
	})
	$form.Controls.Add($updateAll)
	$form.AcceptButton = $updateAll

	#Cancel Button
	$cancel = New-Object System.Windows.Forms.Button -Property @{Text = "Close"; Location = '350,310'; Size = '100,40'}
	$cancel.Add_Click({ 
		if ($dispOpts.preview.PreviewForm -and -not $dispOpts.preview.PreviewForm.IsDisposed) {
            $dispOpts.preview.PreviewForm.Close()
            $dispOpts.preview.PreviewForm = $null
		}
		$form.Close()
		$form.Dispose()
	})
	$form.Controls.Add($cancel)
	$form.CancelButton = $cancel
	
	$form.ShowDialog()
}

function Default-Properties {
	$properties = @{
		workPeriod = 3000.0
		pomodoro = $false
		numPomodoros = 4.0
		startTime = "09:00"
		endTime = "18:00"
		days = "Monday", "Tuesday", "Wednesday", "Thursday", "Friday"
		shortBreak = 5.0
		lockOut = 10.0
		eveningLO = $true
		duration = 60.0
		exitDifficulty = 0
		reminderPopups = $true
		sounds = $true
		showPie = $true
		showTime = $true
		timeReminderChime = "$parentDir\assets\sounds\long-chime-sound.mp3"
		workEndChime = "$parentDir\assets\sounds\long-dang.mp3"
		breakEndChime = "$parentDir\assets\sounds\alarm-bell.mp3"
		volume = 500
		pieChartClr = [System.Drawing.Color]::CornflowerBlue
		textDispClr = [System.Drawing.Color]::Black	
		scheduled = $true
		cycles = 2
	}
	Save-Properties -properties $properties
}

function Load-Properties {
	param(
		$propertiesPath = "$parentDir/json/properties.json"
	)
	Get-Content $propertiesPath -Raw | ConvertFrom-Json
}

function Save-Properties {
	param(
		$propertiesPath = "$parentDir/json/properties.json",
		$properties
	)
    $properties | ConvertTo-Json | Set-Content $propertiesPath -Encoding UTF8
}

function Get-Property {
	param(
		$propertiesPath = "$parentDir/json/properties.json",
		$propname
	)
	$properties = Load-Properties -propertiesPath $propertiesPath
	return $properties.$propname
}