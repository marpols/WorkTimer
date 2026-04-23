Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

# Create the Form object
$form = New-Object System.Windows.Forms.Form
$form.Text = "Work Timer Properties"
$form.Size = New-Object System.Drawing.Size(480,400)
$form.StartPosition = "CenterScreen"
$form.Icon = New-Object System.Drawing.Icon("$PSScriptRoot\time.ico")

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
$objHours.Value = 0


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
$objMin.Value = 0


$updateWP = New-Object System.Windows.Forms.Button
$updateWP.Location = New-Object System.Drawing.Point(150,90)
$updateWP.AutoSize = $true
$updateWP.Text = "Update work period"


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
$objLO.Value = 0


$updateLO = New-Object System.Windows.Forms.Button
$updateLO.Location = New-Object System.Drawing.Point(150,155)
$updateLO.AutoSize = $true
$updateLO.Text = "Update lockout"

#Evening Lockout
$checkbox = New-Object System.Windows.Forms.CheckBox -Property @{Text = "Enable evening lockout"; Location='20,230'; AutoSize=$true}
$form.Controls.Add($checkbox)
$chkLabel = New-Object System.Windows.Forms.Label -Property @{Text="Duration:"; Location='20,265'; AutoSize=$true}
$objELO = New-Object System.Windows.Forms.NumericUpDown -Property @{Location='70,260'; Size='50,50'; Minimum=20; Maximum=60; Value=60}
$chkLabel2 = New-Object System.Windows.Forms.Label -Property @{Text="Minutes"; Location='120,265'; AutoSize=$true}
$updateELO = New-Object System.Windows.Forms.Button -Property @{Text="Update"; Location='164,225';AutoSize=$true}
$form.Controls.Add($updateELO)
$checkbox.Add_CheckedChanged({
	  if ($checkbox.Checked) {
		$form.Controls.Add($chkLabel)
		$form.Controls.Add($objELO)
		$form.Controls.Add($chkLabel2)
        $chkLabel.Visible = $true
		$objELO.Visible = $true
		$chkLabel2.Visible = $true
    } else {
        $chkLabel.Visible = $false
		$objELO.Visible = $false
		$chkLabel2.Visible = $false
    }
})


$clb = New-Object System.Windows.Forms.CheckedListBox -Property @{AutoSize=$true; Location='300,10'; CheckOnClick = $true}
$clb.Items.AddRange(@("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"))


for ($i = 0; $i -lt $clb.Items.Count; $i++) {
    $clb.SetItemChecked($i, $true)
}


$btn = New-Object System.Windows.Forms.Button -Property @{Text="Update days of the week"; AutoSize = $true; Location='300,125'}
$btn.Add_Click({ $script:results = $clb.CheckedItems; $form.Close() })
$form.Controls.AddRange(@($clb, $btn))

#Timeframe
$timePickerStart = New-Object System.Windows.Forms.DateTimePicker -Property @{Format='Custom'; CustomFormat = "HH:mm"; Value = "09:00"; ShowUpDown=$true; Location='300,180'; Size='150,20'}
$timePickerEnd = New-Object System.Windows.Forms.DateTimePicker -Property @{Format='Custom'; CustomFormat = "HH:mm"; Value = "18:00"; ShowUpDown=$true; Location='300,220'; Size='150,20'}
$okButton = New-Object System.Windows.Forms.Button -Property @{Text='Update schedule'; Location='300,245'; AutoSize = $true}

# Add Controls and OK logic
$form.Controls.AddRange(@($timePickerStart, $timePickerEnd, $okButton, (New-Object System.Windows.Forms.Label -Property @{Text='Start Time:'; Location='300,165'}), (New-Object System.Windows.Forms.Label -Property @{Text='End Time:'; Location='300,205'})))
$okButton.Add_Click({ $script:StartTime = $timePickerStart.Value; $script:EndTime = $timePickerEnd.Value; $form.Close() })


$verticalLine = New-Object Windows.Forms.Panel -Property @{Width=1; Height=200; Left=275; Top=20; BorderStyle="Fixed3D"; BackColor = [System.Drawing.Color]::Gray}
$form.Controls.Add($verticalLine)


$updateAll = New-Object System.Windows.Forms.Button -Property @{Location='245,310'; Size='100,40'; Text="Update All"}
$form.Controls.Add($updateAll)

$cancel = New-Object System.Windows.Forms.Button
$cancel.Location = New-Object System.Drawing.Point(350,310)
$cancel.Size = New-Object System.Drawing.Size(100,40)
$cancel.Text = "Close"

$cancel.Add_Click({ $form.Close()})

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
$form.Add($verticalLine)
[void]$form.ShowDialog()


function HM-S($hours, $minutes){
return 60 * (60 * $hours + $minutes)
}

function S-HM($seconds){
$value = $seconds/3600
$hours = [Math]::Truncate($value)
$minutes = ($value-$hours)*60
return $hours, $minutes
}	
