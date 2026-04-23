function Show-Properties {
	Add-Type -AssemblyName System.Drawing
	Add-Type -AssemblyName System.Windows.Forms
	
	$state = Load-State
	$properties = Load-Properties
	$curHours, $curMin = S-HM $properties.workPeriod
	
	$form = New-Object System.Windows.Forms.Form -Property @{Text = "Work Timer Properties"; Size = New-Object System.Drawing.Size(480,400); StartPosition = "CenterScreen"; Icon = New-Object System.Drawing.Icon("$PSScriptRoot\time.ico")}

	#Work Period
	#title
	$titleWP = New-Object System.Windows.Forms.Label
	$titleWP.Text = "Set work period duration:"
	$titleWP.Location = New-Object System.Drawing.Point(10,20)
	$titleWP.AutoSize = $true

	# Hours
	$labelHours = New-Object System.Windows.Forms.Label
	$labelHours.Text = "Hours"
	$labelHours.Location = New-Object System.Drawing.Point(84,54)
	$labelHours.AutoSize = $true

	$objHours = New-Object System.Windows.Forms.NumericUpDown
	$objHours.Location = New-Object System.Drawing.Point(30,50)
	$objHours.Size = New-Object System.Drawing.Size(50,50)
	$objHours.Maximum = 4
	$objHours.Minimum = 0
	$objHours.Value = $curHours


	#minutes
	$labelMin = New-Object System.Windows.Forms.Label
	$labelMin.Text = "Minutes"
	$labelMin.Location = New-Object System.Drawing.Point(194,54)
	$labelMin.AutoSize = $true

	$objMin = New-Object System.Windows.Forms.NumericUpDown
	$objMin.Location = New-Object System.Drawing.Point(140,50)
	$objMin.Size = New-Object System.Drawing.Size(50,50)
	$objMin.Maximum = 59
	$objMin.Minimum = 0
	$objMin.Value = $curMin
	

	$updateWP = New-Object System.Windows.Forms.Button
	$updateWP.Location = New-Object System.Drawing.Point(150,90)
	$updateWP.AutoSize = $true
	$updateWP.Text = "Update work period"
	
	$updateWP.Add_Click({
		$time = HM-S $objHours.Value $objMin.Value
		$properties.workPeriod = $time
		Save-Properties $properties
		Show-Balloon "Work period duration updated to $($objHours.Value) hour(s) and $($objMin.Value) minute(s).`nChanges will take effect in the next cycle." "Work Timer Update"
	})

	#Lockout
	#title
	$titleLO = New-Object System.Windows.Forms.Label
	$titleLO.Text = "Set lockout duration:"
	$titleLO.Location = New-Object System.Drawing.Point(10,130)
	$titleLO.AutoSize = $true

	$labelLO = New-Object System.Windows.Forms.Label
	$labelLO.Text = "Minutes"
	$labelLO.Location = New-Object System.Drawing.Point(84,164)
	$labelLO.AutoSize = $true

	$objLO = New-Object System.Windows.Forms.NumericUpDown
	$objLO.Location = New-Object System.Drawing.Point(30,160)
	$objLO.Size = New-Object System.Drawing.Size(50,50)
	$objLO.Maximum = 60
	$objLO.Minimum = 0
	$objLO.Value = $properties.lockOut
	

	$updateLO = New-Object System.Windows.Forms.Button
	$updateLO.Location = New-Object System.Drawing.Point(150,155)
	$updateLO.AutoSize = $true
	$updateLO.Text = "Update lockout"

	$updateLO.Add_Click({ 
		$properties.lockOut = $objLO.Value
		Save-Properties $properties
		Show-Balloon "Lockout duration updated to $($objLO.Value) minutes.`nChanges will take effect in the next cycle." "Work Timer Update"
	})
	
	#Evening Lockout
	$checkbox = New-Object System.Windows.Forms.CheckBox -Property @{Text = "Enable evening lockout"; Location='20,230'; AutoSize=$true}
	$checkbox.Checked = $properties.eveningLO
	#$info.icon = [System.Drawing.SystemIcons]::Information -Property @{Location='10,10';Size='10,10'; Image=[System.Drawing.SystemIcons]::Information.ToBitmap()}
	#$form.Controls.Add($info)
	$tooltip = New-Object System.Windows.Forms.ToolTip
	$tooltip.SetToolTip($checkbox, "Set a longer lockout period for the end of your workday.")
	$form.Controls.Add($checkbox)
	
	$chkLabel = New-Object System.Windows.Forms.Label -Property @{Text="Duration:"; Location='20,265'; AutoSize=$true}
	$objELO = New-Object System.Windows.Forms.NumericUpDown -Property @{Location='70,260'; Size='50,50'; Minimum=20; Maximum=60; Value=$properties.duration}
	$chkLabel2 = New-Object System.Windows.Forms.Label -Property @{Text="Minutes"; Location='120,265'; AutoSize=$true}
	$updateELO = New-Object System.Windows.Forms.Button -Property @{Text="Update"; Location='164,225';AutoSize=$true}
	$form.Controls.Add($updateELO)
	
	if($checkbox.Checked){
			$chkLabel.Enabled = $true
			$objELO.Enabled = $true
			$chkLabel2.Enabled = $true
	} else {
			$chkLabel.Enabled = $false
			$objELO.Enabled = $false
			$chkLabel2.Enabled = $false
	}
	$checkbox.Add_CheckedChanged({
		  if ($checkbox.Checked) {
			$chkLabel.Enabled = $true
			$objELO.Enabled = $true
			$chkLabel2.Enabled = $true
		} else {
			$chkLabel.Enabled = $false
			$objELO.Enabled = $false
			$chkLabel2.Enabled = $false
		}
	})
	$form.Controls.Add($chkLabel)
	$form.Controls.Add($objELO)
	$form.Controls.Add($chkLabel2)
	$updateELO.Add_Click({
		$properties.eveningLO = $checkbox.Checked
		$properties.duration = $objELO.Value
		Save-Properties $properties
		if($checkbox.Checked){
			$msg = "Evening Lockout Enabled for $($objELO.Value) minutes."
		} else{
			$msg = "Evening Lockout Disabled."
		}
		Show-Balloon $msg "Work Timer Update"
	})
	
	#Days of the Week
	$clb = New-Object System.Windows.Forms.CheckedListBox -Property @{AutoSize=$true; Location='300,10'; CheckOnClick = $true}
	$clb.Items.AddRange(@("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"))


	for ($i = 0; $i -lt $clb.Items.Count; $i++) {
		if($clb.Items[$i].ToString() -in $properties.days){
			$clb.SetItemChecked($i, $true)
		}
	}
	
	$updateDays = New-Object System.Windows.Forms.Button -Property @{Text="Update days of the week"; AutoSize = $true; Location='300,125'}
	$updateDays.Add_Click({ 
		$properties.days = @($clb.CheckedItems | ForEach-Object { $_.ToString() })
		Save-Properties $properties
		Show-Balloon "Work Timer will now be active on $($clb.CheckedItems).`nChanges will take effect on restart." "Work Timer Update"
	})
	$form.Controls.AddRange(@($clb, $updateDays))


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
		$form.Controls.AddRange(@($timePickerStart, $timePickerEnd, $updateTime, (New-Object System.Windows.Forms.Label -Property @{Text='Start Time:'; Location='300,165'}), (New-Object System.Windows.Forms.Label -Property @{Text='End Time:'; Location='300,205'})))


	$verticalLine = New-Object System.Windows.Forms.Panel -Property @{Width=1; Height=200; Left=275; Top=20; BorderStyle="Fixed3D"; BackColor = [System.Drawing.Color]::Gray}
	$form.Controls.Add($verticalLine)


	$updateAll = New-Object System.Windows.Forms.Button -Property @{Location='245,310'; Size='100,40'; Text="Update All"}
	$updateAll.Add_Click({
		$time = HM-S $objHours.Value $objMin.Value
		$properties.workPeriod = $time
		$properties.lockOut = $objLO.Value
		$properties.days = @($clb.CheckedItems | ForEach-Object { $_.ToString() })
		if(Check-Hours $timePickerStart.Value $timePickerEnd.Value $form){
			$form.Refresh()
			$form.Activate()
		} else {
			$properties.startTime = $timePickerStart.Value.ToString("HH:mm")
			$properties.endTime = $timePickerEnd.Value.ToString("HH:mm")
		}
		$properties.eveningLO = $checkbox.Checked
		$properties.duration = $objELO.Value
		Save-Properties $properties
		if($checkbox.Checked){ 
			$text = "enabled" 
		} else { 
			$text = "disabled" 
		}
		Show-Balloon "New Values:`nWork Period Duration: $($objHours.Value) hour(s) $($objMin.Value) minute(s)`nLockout Duration: $($objLO.Value)`nDays: $($clb.CheckedItems | ForEach-Object { $_[0] })`nHours: $($timePickerStart.Value.ToString("HH:mm")) - $($timePickerEnd.Value.ToString("HH:mm"))`nEvening lockout $text`nChanges to work period and lockout will take place in the next cycle.`nChanges to days and hours will be applied on restart." "Work Timer Update"    
	})
	$form.Controls.Add($updateAll)

	$cancel = New-Object System.Windows.Forms.Button
	$cancel.Location = New-Object System.Drawing.Point(350,310)
	$cancel.Size = New-Object System.Drawing.Size(100,40)
	$cancel.Text = "Close"

	$cancel.Add_Click({ 
		$form.Close()
		$form.Dispose()
	})

	# Add the button to the form and show it
	$form.Controls.Add($titleWP)
	$form.Controls.Add($labelHours)
	$form.Controls.Add($objHours)
	$form.Controls.Add($labelMin)
	$form.Controls.Add($objMin)
	$form.Controls.Add($updateWP)
	$form.Controls.Add($titleLO)
	$form.Controls.Add($labelLO)
	$form.Controls.Add($objLO)
	$form.Controls.Add($updateLO)
	$form.Controls.Add($cancel)
	
	$form.AcceptButton = $updateAll
	$form.CancelButton = $cancel
	
	try {
        $result = $form.ShowDialog()
        if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
            return @{
                # values here
            }
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
