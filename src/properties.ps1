function Show-Properties {
	Add-Type -AssemblyName System.Drawing
	Add-Type -AssemblyName System.Windows.Forms
	
	$parentDir = Split-Path -Path $PSScriptRoot -Parent
	$state = Load-State
	$properties = Load-Properties
	$curHours, $curMin = S-HM $properties.workPeriod
	
	$form = New-Object System.Windows.Forms.Form -Property @{Text = "Work Timer Properties"; Size = '480,400'; StartPosition = "CenterScreen"; Icon = New-Object System.Drawing.Icon("$parentDir\assets\time.ico")}

	$tabControl = New-Object System.Windows.Forms.TabControl -Property @{Dock = "Top"; Size = '480,300'}
	
	$setPage = New-Object System.Windows.Forms.TabPage -Property @{Text = "Settings"}
	$schedPage = New-Object System.Windows.Forms.TabPage -Property @{Text = "Schedule"}
	$diffPage = New-Object System.Windows.Forms.TabPage -Property @{Text = "Exit Difficulty"}
	
	$tabControl.Controls.AddRange(@($setPage, $schedPage, $diffPage))
	$form.Controls.Add($tabControl)

	#Mode
	$checkboxPom = New-Object System.Windows.Forms.Checkbox -Property @{Text = "Pomodoro"; Location='30,10'; AutoSize=$true; Checked = $properties.pomodoro}
	$tooltip = New-Object System.Windows.Forms.ToolTip
	$tooltip.SetToolTip($checkboxPom, "If checked allows setting a short break time and longer break time seperately.")
	$setPage.Controls.Add($checkboxPom)
	
	#Work Period
	$objHours = New-Object System.Windows.Forms.NumericUpDown -Property @{Location = '30,60'; Size = '50,50'; Maximum = 4; Minimum = 0; Value = $curHours}
	$objMin = New-Object System.Windows.Forms.NumericUpDown -Property @{Location = '140,60'; Size = '50,50'; Maximum = 59; Minimum = 0; Value = $curMin}

	$updateWP = New-Object System.Windows.Forms.Button -Property @{Text = "Set work period"; Location = '140,90'; AutoSize = $true}
	$updateWP.Add_Click({
		$time = HM-S $objHours.Value $objMin.Value
		$properties.workPeriod = $time
		Save-Properties $properties
		Show-Balloon "Work period duration updated to $($objHours.Value) hour(s) and $($objMin.Value) minute(s).`nChanges will take effect in the next cycle." "Work Timer Update"
	})
	$setPage.Controls.AddRange(@($objHours, $objMin, $updateWP,
	(New-Object System.Windows.Forms.Label -Property @{Text = "Work period length:"; Location = '10,40'; Autosize = $true}),
	(New-Object System.Windows.Forms.Label -Property @{Text = "Hours"; Location = '84,65'; AutoSize = $true}),
	(New-Object System.Windows.Forms.Label -Property @{Text = "Minutes"; Location = '194,65'; AutoSize = $true})))

	#Lockout
	$objLO = New-Object System.Windows.Forms.NumericUpDown -Property @{Location = '30,140'; Size = '50,50'; Maximum = 60; Minimum = 0; Value = $properties.lockOut}
	$titleLO = New-Object System.Windows.Forms.Label -Property @{Text = "Lockout length:"; Location = '10,120'; Autosize = $true}
	$updateLO = New-Object System.Windows.Forms.Button -Property @{Text = "Set lockout"; Location = '140,140'; Autosize = $true}
	$updateLO.Add_Click({ 
		$properties.pomodoro = $false
		$properties.lockOut = $objLO.Value
		Save-Properties $properties
		Show-Balloon "Lockout duration updated to $($objLO.Value) minutes.`nChanges will take effect in the next cycle." "Work Timer Update"
	})

	$titleLB = New-Object System.Windows.Forms.Label -Property @{Text = "Long break length:"; Location = '10,120'; Autosize = $true}
	
	#Short break
	$objSB = New-Object System.Windows.Forms.NumericUpDown -Property @{Location = '30,190'; Size = '50,50'; Maximum = 60; Minimum = 0; Value = $properties.shortBreak}
	$titleSB = New-Object System.Windows.Forms.Label -Property @{Text = "Short break length:"; Location = '10,170'; Autosize = $true}
	$labelSB = New-Object System.Windows.Forms.Label -Property @{Text = "Minutes"; Location = '84,195'; Autosize = $true}
	
	#number of Pomodoros
	$pomNum = New-Object System.Windows.Forms.NumericUpDown -Property @{Location = '30,240'; Size = '50,50'; Maximum = 6; Minimum = 2; Value = $properties.numPomodoros}
	$pomTitle = New-Object System.Windows.Forms.Label -Property @{Text = "Number of pomodoros:"; Location = '10,220'; Autosize = $true}
	$tooltip = New-Object System.Windows.Forms.ToolTip
	$tooltip.SetToolTip($pomTitle,  "Enter the number of pomodoros (work period + breaks). The last break will be a long break.")
	
	$updatePom = New-Object System.Windows.Forms.Button -Property @{Text = "Set pomodoro"; Location = '140,240'; Autosize = $true}
	$updatePom.Add_Click({ 
		$properties.pomodoro = $true
		$properties.lockOut = $objLO.Value
		$properties.shortBreak = $objSB.Value
		$properties.numPomodoros = $pomNum.Value
		Save-Properties $properties
		Show-Balloon "Pomodoro updated:`nShort Break: $($objSB.Value) minutes.`nLong Break: $($objLO.Value) minutes.`nNumber of Pomodoros: $($pomNum.Value)`nChanges will take effect in the next cycle." "Work Timer Update"
	})
	
	$controlsLO = @($titleLO, $updateLO)
	$controlsPom = @($titleLB, $objSB, $titleSB, $labelSB, $pomNum, $pomTitle, $updatePom)
	
	if($checkboxPom.Checked){
		Set-ControlsVisible $true $controlsPom
		Set-ControlsVisible $false $controlsLO
	} else {
		Set-ControlsVisible $false $controlsPom
		Set-ControlsVisible $true $controlsLO
	}
	$checkboxPom.Add_CheckedChanged({
		  if ($checkboxPom.Checked) {
			Set-ControlsVisible $true $controlsPom
			Set-ControlsVisible $false $controlsLO
		} else {
			Set-ControlsVisible $false $controlsPom
			Set-ControlsVisible $true $controlsLO
		}
	})
	$setPage.Controls.AddRange(@($objLO, $titleLO, $updateLO,
	(New-Object System.Windows.Forms.Label -Property @{Text = "Minutes"; Location = '84,145'; Autosize = $true})))
	
	$setPage.Controls.AddRange($controlsPom)
	
	#Evening Lockout
	$checkboxELO = New-Object System.Windows.Forms.Checkbox -Property @{Text = "Enable evening lockout"; Location='290,10'; AutoSize=$true; Checked = $properties.eveningLO}
	$tooltip = New-Object System.Windows.Forms.ToolTip
	$tooltip.SetToolTip($checkboxELO, "Set a longer lockout period for the end of your workday.")
	
	$labelELO = New-Object System.Windows.Forms.Label -Property @{Text="Duration:"; Location='290,40'; AutoSize=$true}
	$objELO = New-Object System.Windows.Forms.NumericUpDown -Property @{Location='310,60'; Size='50,50'; Minimum=20; Maximum=60; Value=$properties.duration}
	$labelELO2 = New-Object System.Windows.Forms.Label -Property @{Text="Minutes"; Location='364,65'; AutoSize=$true}
	$updateELO = New-Object System.Windows.Forms.Button -Property @{Text="Update"; Location='290,90';AutoSize=$true}
	
	$controlsELO = @($objELO, $labelELO, $labelELO2) 
	
	if($checkboxELO.Checked){
		Set-ControlsEnabled $true $controlsELO
	} else {
		Set-ControlsEnabled $false $controlsELO
	}
	$checkboxELO.Add_CheckedChanged({
		  if ($checkboxELO.Checked) {
			Set-ControlsEnabled $true $controlsELO
		} else {
			Set-ControlsEnabled $false $controlsELO
		}
	})
	$setPage.Controls.AddRange(@($objELO, $labelELO, $labelELO2, $checkboxELO, $updateELO))
	$updateELO.Add_Click({
		$properties.eveningLO = $checkboxELO.Checked
		$properties.duration = $objELO.Value
		Save-Properties $properties
		if($checkboxELO.Checked){
			$msg = "Evening Lockout Enabled for $($objELO.Value) minutes."
		} else{
			$msg = "Evening Lockout Disabled."
		}
		Show-Balloon $msg "Work Timer Update"
	})
	
	$verticalLine = New-Object System.Windows.Forms.Panel -Property @{Width=1; Height=200; Left=275; Top=20; BorderStyle="Fixed3D"; BackColor = [System.Drawing.Color]::Gray}
	$setPage.Controls.Add($verticalLine)
	
	#Days of the Week
	$daysList = New-Object System.Windows.Forms.CheckedListBox -Property @{Location='80,10'; AutoSize=$true; CheckOnClick = $true}
	$daysList.Items.AddRange(@("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"))

	for ($i = 0; $i -lt $daysList.Items.Count; $i++) {
		if($daysList.Items[$i].ToString() -in $properties.days){
			$daysList.SetItemChecked($i, $true)
		}
	}
	
	$weekDays = New-Object System.Windows.Forms.RadioButton -Property @{Text = "Weekdays Only"; Location='80,145'; AutoSize=$true}
	$weekEnds = New-Object System.Windows.Forms.RadioButton -Property @{Text = "Weekends Only"; Location='80,165'; AutoSize=$true}
	$allDays = New-Object System.Windows.Forms.RadioButton -Property @{Text = "Daily"; Location='80,185'; AutoSize=$true}
	
	$isWeekdays = (@(0..4) | Where-Object {
    -not $daysList.GetItemChecked($_)
		}).Count -eq 0
	$isWeekends = (@(5,6) | Where-Object {
    -not $daysList.GetItemChecked($_)
		}).Count -eq 0
	$isAll = (@(0..6) | Where-Object {
    -not $daysList.GetItemChecked($_)
		}).Count -eq 0
		
	if($isAll){
		$allDays.Checked = $true
	} elseif ($isWeekends){
		$weekEnds.Checked = $true
	} elseif ($isWeekdays) {
		$weekDays.Checked = $true
	}
	
	$daysList.Add_ItemCheck({
		param($sender, $e)

		$checkedAfterChange = @($sender.CheckedIndices)

		if ($e.NewValue -eq [System.Windows.Forms.CheckState]::Checked) {
			$checkedAfterChange += $e.Index
		} else {
			$checkedAfterChange = $checkedAfterChange | Where-Object { $_ -ne $e.Index }
		}

		$matchWeekdays =
			((@(0..4)| Sort-Object) -join ',') -eq
			(($checkedAfterChange | Sort-Object) -join ',')
		$matchWeekends =
			((@(5,6)| Sort-Object) -join ',') -eq
			(($checkedAfterChange | Sort-Object) -join ',')
		$matchAll =
			((@(0..6)| Sort-Object) -join ',') -eq
			(($checkedAfterChange | Sort-Object) -join ',')

		if ($matchAll) {
			
			$allDays.Checked = $true
		} elseif ($matchWeekends) {
			$weekEnds.Checked = $true
		} elseif ($matchWeekdays){
			$weekDays.Checked = $true
		} else {
			$weekDays.Checked = $false
			$weekEnds.Checked = $false
			$allDays.Checked = $false
		}
	})
	
	$weekDays.Add_CheckedChanged({
		if ($weekDays.Checked){
			0..4 | ForEach-Object {
				$daysList.SetItemChecked($_, $true)
			}	
			$daysList.SetItemChecked(5, $false)
			$daysList.SetItemChecked(6, $false)
		}
	}) 
	$weekEnds.Add_CheckedChanged({
		if ($weekEnds.Checked){
			0..4 | ForEach-Object {
				$daysList.SetItemChecked($_, $false)
			}
			$daysList.SetItemChecked(5, $true)
			$daysList.SetItemChecked(6, $true)
		}
	}) 
	$allDays.Add_CheckedChanged({
		if ($allDays.Checked){
			0..6 | ForEach-Object {
				$daysList.SetItemChecked($_, $true)
			}
		}
	})
	
	$updateDays = New-Object System.Windows.Forms.Button -Property @{Text="Set days of the week"; Location='80,210'; AutoSize = $true}
	$updateDays.Add_Click({ 
		$properties.days = @($daysList.CheckedItems | ForEach-Object { $_.ToString() })
		Save-Properties $properties
		Show-Balloon "Work Timer will now be active on $($daysList.CheckedItems).`nChanges will take effect on restart." "Work Timer Update"
	})
	$controlsSched = @($daysList, $updateDays, $weekDays, $weekEnds, $allDays)
	$schedPage.Controls.AddRange($controlsSched)


	#Timeframe
	$timePickerStart = New-Object System.Windows.Forms.DateTimePicker -Property @{Format='Custom'; CustomFormat = "HH:mm"; Value = Str-to-Date($properties.startTime); ShowUpDown=$true; Location='240,25'; Size='150,20'}
	$timePickerEnd = New-Object System.Windows.Forms.DateTimePicker -Property @{Format='Custom'; CustomFormat = "HH:mm"; Value = Str-to-Date($properties.endTime); ShowUpDown=$true; Location='240,65'; Size='150,20'}
	$updateTime = New-Object System.Windows.Forms.Button -Property @{Text='Set schedule'; Location='240,90'; AutoSize = $true}
	$updateTime.Add_Click({
		if(Check-Hours $timePickerStart.Value $timePickerEnd.Value $form){
			$form.Refresh()
			$form.Activate()
		} else {
			$properties.startTime = $timePickerStart.Value.ToString("HH:mm")
			$properties.endTime = $timePickerEnd.Value.ToString("HH:mm")
			Save-Properties $properties
			Show-Balloon "Work Timer will now be active between $($timePickerStart.Value.ToString("HH:mm")) and $($timePickerEnd.Value.ToString("HH:mm")).`nChanges will take effect on restart." "Work Timer Update"
		}
	})
	$schedPage.Controls.AddRange(@($timePickerStart, $timePickerEnd, $updateTime, 
	(New-Object System.Windows.Forms.Label -Property @{Text='Start Time:'; Location='240,10'}), (New-Object System.Windows.Forms.Label -Property @{Text='End Time:'; Location='240,50'})))


	#Difficulty
	$diffSlider = New-Object System.Windows.Forms.TrackBar -Property @{Location = '80, 100'; Size = '300,100'; Minimum = 0; Maximum = 2; TickFrequency = 1; LargeChange = 1; SmallChange = 1; Value = $properties.exitDifficulty}
	$updateDiff = New-Object System.Windows.Forms.Button -Property @{Text='Set difficulty'; Location='195,170'; AutoSize = $true}
	$updateDiff.Add_Click({
		$properties.exitDifficulty = $diffSlider.Value
		Save-Properties $properties
		Show-Balloon "Exit challenge difficulty has been set to: $($difficulty[$diffSlider.Value])" "Work Timer Update"
	})
	$diffPage.Controls.AddRange(@(
	(New-Object System.Windows.Forms.Label -Property @{Text='Easy'; Location='80,130'}),
	(New-Object System.Windows.Forms.Label -Property @{Text='Medium'; Location='210,130'}),
	(New-Object System.Windows.Forms.Label -Property @{Text='Hard'; Location='352,130'}),
	$diffSlider,
	$updateDiff))

	#Update All Button
	$updateAll = New-Object System.Windows.Forms.Button -Property @{Location='247,310'; Size='100,40'; Text="Update All"}
	$updateAll.Add_Click({
		$time = HM-S $objHours.Value $objMin.Value
		$properties.workPeriod = $time
		$properties.lockOut = $objLO.Value
		$properties.pomodoro = $checkboxPom.Checked
		if($checkboxPom.Checked){
					$properties.shortBreak = $objSB.Value
					$properties.numPomodoros = $pomNum.Value
		}
		$properties.days = @($daysList.CheckedItems | ForEach-Object { $_.ToString() })
		if(Check-Hours $timePickerStart.Value $timePickerEnd.Value $form){
			$form.Refresh()
			$form.Activate()
		} else {
			$properties.startTime = $timePickerStart.Value.ToString("HH:mm")
			$properties.endTime = $timePickerEnd.Value.ToString("HH:mm")
		}
		$properties.eveningLO = $checkboxELO.Checked
		$properties.duration = $objELO.Value
		$properties.exitDifficulty = $diffSlider.Value
		Save-Properties $properties
		Show-Balloon "All settings have been updated.`nChanges to work period and lockouts will take place in the next cycle.`nChanges to days and hours will be applied on restart."
	})
	$form.Controls.Add($updateAll)
	$form.AcceptButton = $updateAll

	#Cancel Button
	$cancel = New-Object System.Windows.Forms.Button -Property @{Text = "Close"; Location = '350,310'; Size = '100,40'}
	$cancel.Add_Click({ 
		$form.Close()
		$form.Dispose()
	})
	$form.Controls.Add($cancel)
	$form.CancelButton = $cancel
	

	
	$form.ShowDialog()
}

function HM-S($hours, $minutes){
	return 60 * (60 * $hours + $minutes)
}

function S-HM($seconds){
	$value = $seconds/3600
	$hours = [Math]::Truncate($value)
	$minutes = ($value-$hours)*60
	return $hours, $minutes
}

function Check-Hours ($start, $end, $form){
	if($start -ge $end){
		$title = "Schedule Error"
		$text = "End time must be greater than start time."
		[System.Windows.Forms.MessageBox]::Show(
			$form,
			$text,
			$title,
			[System.Windows.Forms.MessageBoxButtons]::OK,
			[System.Windows.Forms.MessageBoxIcon]::Error
		) | Out-Null
	}
	return $start -ge $end
}

function Set-ControlsVisible {
    param(
        [bool]$Visible,
        [System.Windows.Forms.Control[]]$Controls
    )
    foreach ($control in $Controls) {
        if ($null -ne $control) {
            $control.Visible = $Visible
        }
    }
}

function Set-ControlsEnabled {
    param(
        [bool]$Enable,
        [System.Windows.Forms.Control[]]$Controls
    )
    foreach ($control in $Controls) {
        if ($null -ne $control) {
            $control.Enabled = $Enable
        }
    }
}

function Load-Properties {
	Get-Content $propertiesPath -Raw | ConvertFrom-Json
}

function Save-Properties($properties) {
    $properties | ConvertTo-Json | Set-Content $propertiesPath -Encoding UTF8
}

function Get-Property($propname){
	$properties = Load-Properties
	return $properties.$propname
}