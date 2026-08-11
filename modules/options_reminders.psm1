function reminder-options {
    param(
        $page,
        $properties
    )

    #Popups
	$popupCheck = New-Object System.Windows.Forms.Checkbox -Property @{
		Text = "Popups";
		Location='10,10';
		Autosize=$true;
		Checked = $properties.reminderPopups
	}
	$popupTooltip = New-Object System.Windows.Forms.ToolTip
	$popuptooltip.SetToolTip($popupcheck, "Turn popup time reminders on or off")

	#Sounds
	$soundsCheck = New-Object System.Windows.Forms.Checkbox -Property @{
		Text = "Reminder sounds";
		Location='10,40';
		Autosize=$true;
		Size = '20,20'
		Checked = $properties.sounds
	}
	$soundsTooltip = New-Object System.Windows.Forms.ToolTip
	$soundsTooltip.SetToolTip($soundsCheck, "Turn sound reminders on or off")

    $controlsRem = @($popupCheck, $soundsCheck)

    $Page.Controls.AddRange($controlsRem)

    return @{
        popups = $popupCheck
        sounds = $soundsCheck
    }
}