Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationFramework
[System.Windows.Forms.Application]::EnableVisualStyles()

function Show-Properties {
	Add-Type -AssemblyName System.Drawing
	Add-Type -AssemblyName System.Windows.Forms
	
	$state = Load-State
	$properties = Load-Properties
	$curHours, $curMin = S-HM $properties.workPeriod
	
	$form = New-Object System.Windows.Forms.Form -Property @{Text = "Work Timer Properties"; Size = '480,400'; StartPosition = "CenterScreen"; Icon = New-Object System.Drawing.Icon("$PSScriptRoot\time.ico")}

	#Work Period
	$objHours = New-Object System.Windows.Forms.NumericUpDown -Property @{Location = '30,50'; Size = '50,50'; Maximum = 4; Minimum = 0; Value = $curHours}
	$objMin = New-Object System.Windows.Forms.NumericUpDown -Property @{Location = '140,50'; Size = '50,50'; Maximum = 59; Minimum = 0; Value = $curMin}

	$updateWP = New-Object System.Windows.Forms.Button -Property @{Text = "Update work period"; Location = '150,90'; AutoSize = $true}
	$updateWP.Add_Click({
		$time = HM-S $objHours.Value $objMin.Value
		$properties.workPeriod = $time
		Save-Properties $properties
		Show-Balloon "Work period duration updated to $($objHours.Value) hour(s) and $($objMin.Value) minute(s).`nChanges will take effect in the next cycle." "Work Timer Update"
	})
	$form.Controls.AddRange(@($objHours, $objMin, $updateWP,
	(New-Object System.Windows.Forms.Label -Property @{Text = "Set work period duration:"; Location = '10,20'; Autosize = $true}),
	(New-Object System.Windows.Forms.Label -Property @{Text = "Hours"; Location = '84,54'; AutoSize = $true}),
	(New-Object System.Windows.Forms.Label -Property @{Text = "Minutes"; Location = '194,54'; AutoSize = $true})))

	#Lockout
	$objLO = New-Object System.Windows.Forms.NumericUpDown -Property @{Location = '30,160'; Size = '50,50'; Maximum = 60; Minimum = 0; Value = $properties.lockOut}
	$updateLO = New-Object System.Windows.Forms.Button -Property @{Text = "Update lockout"; Location = '150,155'; Autosize = $true}
	$updateLO.Add_Click({ 
		$properties.lockOut = $objLO.Value
		Save-Properties $properties
		Show-Balloon "Lockout duration updated to $($objLO.Value) minutes.`nChanges will take effect in the next cycle." "Work Timer Update"
	})
	$form.Controls.AddRange(@($objLO, $updateLO,
	(New-Object System.Windows.Forms.Label -Property @{Text = "Set lockout duration:"; Location = '10,130'; Autosize = $true}),
	(New-Object System.Windows.Forms.Label -Property @{Text = "Minutes"; Location = '84,164'; Autosize = $true})))

	
	#Evening Lockout
	$checkboxELO = New-Object System.Windows.Forms.Checkbox -Property @{Text = "Enable evening lockout"; Location='20,230'; AutoSize=$true; Checked = $properties.eveningLO}
	$tooltip = New-Object System.Windows.Forms.ToolTip
	$tooltip.SetToolTip($checkboxELO, "Set a longer lockout period for the end of your workday.")
	
	$labelELO = New-Object System.Windows.Forms.Label -Property @{Text="Duration:"; Location='20,265'; AutoSize=$true}
	$objELO = New-Object System.Windows.Forms.NumericUpDown -Property @{Location='70,260'; Size='50,50'; Minimum=20; Maximum=60; Value=$properties.duration}
	$labelELO2 = New-Object System.Windows.Forms.Label -Property @{Text="Minutes"; Location='120,265'; AutoSize=$true}
	$updateELO = New-Object System.Windows.Forms.Button -Property @{Text="Update"; Location='164,225';AutoSize=$true}
	
	if($checkboxELO.Checked){
			$labelELO.Enabled = $true
			$objELO.Enabled = $true
			$labelELO2.Enabled = $true
	} else {
			$labelELO.Enabled = $false
			$objELO.Enabled = $false
			$labelELO2.Enabled = $false
	}
	$checkboxELO.Add_CheckedChanged({
		  if ($checkboxELO.Checked) {
			$labelELO.Enabled = $true
			$objELO.Enabled = $true
			$labelELO2.Enabled = $true
		} else {
			$labelELO.Enabled = $false
			$objELO.Enabled = $false
			$labelELO2.Enabled = $false
		}
	})
	$form.Controls.AddRange(@($checkboxELO, $objELO, $updateELO,  $labelELO, $labelELO2))
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
	
	#Days of the Week
	$daysList = New-Object System.Windows.Forms.CheckedListBox -Property @{Location='300,10'; AutoSize=$true; CheckOnClick = $true}
	$daysList.Items.AddRange(@("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"))

	for ($i = 0; $i -lt $daysList.Items.Count; $i++) {
		if($daysList.Items[$i].ToString() -in $properties.days){
			$daysList.SetItemChecked($i, $true)
		}
	}
	
	$updateDays = New-Object System.Windows.Forms.Button -Property @{Text="Update days of the week"; Location='300,125'; AutoSize = $true}
	$updateDays.Add_Click({ 
		$properties.days = @($daysList.CheckedItems | ForEach-Object { $_.ToString() })
		Save-Properties $properties
		Show-Balloon "Work Timer will now be active on $($daysList.CheckedItems).`nChanges will take effect on restart." "Work Timer Update"
	})
	$form.Controls.AddRange(@($daysList, $updateDays))


	#Timeframe
	$timePickerStart = New-Object System.Windows.Forms.DateTimePicker -Property @{Format='Custom'; CustomFormat = "HH:mm"; Value = Str-to-Date($properties.startTime); ShowUpDown=$true; Location='300,180'; Size='150,20'}
	$timePickerEnd = New-Object System.Windows.Forms.DateTimePicker -Property @{Format='Custom'; CustomFormat = "HH:mm"; Value = Str-to-Date($properties.endTime); ShowUpDown=$true; Location='300,220'; Size='150,20'}
	$updateTime = New-Object System.Windows.Forms.Button -Property @{Text='Update schedule'; Location='300,245'; AutoSize = $true}
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
	$form.Controls.AddRange(@($timePickerStart, $timePickerEnd, $updateTime, 
	(New-Object System.Windows.Forms.Label -Property @{Text='Start Time:'; Location='300,165'}), (New-Object System.Windows.Forms.Label -Property @{Text='End Time:'; Location='300,205'})))


	#Update All Button
	$updateAll = New-Object System.Windows.Forms.Button -Property @{Location='245,310'; Size='100,40'; Text="Update All"}
	$updateAll.Add_Click({
		$time = HM-S $objHours.Value $objMin.Value
		$properties.workPeriod = $time
		$properties.lockOut = $objLO.Value
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
		Save-Properties $properties
		if($checkboxELO.Checked){ 
			$text = "enabled" 
		} else { 
			$text = "disabled" 
		}
		Show-Balloon "New Values:`nWork Period Duration: $($objHours.Value) hour(s) $($objMin.Value) minute(s)`nLockout Duration: $($objLO.Value)`nDays: $($daysList.CheckedItems | ForEach-Object { $_[0] })`nHours: $($timePickerStart.Value.ToString("HH:mm")) - $($timePickerEnd.Value.ToString("HH:mm"))`nEvening lockout $text`nChanges to work period and lockout will take place in the next cycle.`nChanges to days and hours will be applied on restart." "Work Timer Update"    
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
	
	$verticalLine = New-Object System.Windows.Forms.Panel -Property @{Width=1; Height=200; Left=275; Top=20; BorderStyle="Fixed3D"; BackColor = [System.Drawing.Color]::Gray}
	$form.Controls.Add($verticalLine)
	
	try {
        $result = $form.ShowDialog()
        if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
            return 
        }
    }
    finally {
        $form.Dispose()
    }
	
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

function Load-Properties {
	$propertiesPath = "$PSScriptRoot\properties.json"
	Get-Content $propertiesPath -Raw | ConvertFrom-Json
}

function Load-State {
    $statePath = "$PSScriptRoot\state.json"
    Get-Content $statePath -Raw | ConvertFrom-Json
}

function Str-to-Date($dateStr){
	return [datetime]::Parse($dateStr)
}