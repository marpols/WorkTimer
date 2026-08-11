function diff-options {
    param(
        $page,
        $properties
    )
    
    $diffSlider = New-Object System.Windows.Forms.TrackBar -Property @{Location = '80, 100'; Size = '300,100'; Minimum = 0; Maximum = 2; TickFrequency = 1; LargeChange = 1; SmallChange = 1; Value = $properties.exitDifficulty}
	$updateDiff = New-Object System.Windows.Forms.Button -Property @{Text='Set difficulty'; Location='195,170'; Autosize=$true}

	$updateDiff.Tag = @{
		slider = $diffSlider
		properties = $properties
	}
	

	$updateDiff.Add_Click({
		param($sender, $e)
		$properties = $sender.Tag.properties
		$slider = $sender.Tag.slider

		$properties.exitDifficulty = $slider.Value
		Save-Properties $properties
		Toast-Notification -msg "Exit challenge difficulty has been set to: $($difficulty[$slider.Value])" -header "Work Timer Update"
	})
	$Page.Controls.AddRange(@(
	(New-Object System.Windows.Forms.Label -Property @{Text='Easy'; Location='80,130'}),
	(New-Object System.Windows.Forms.Label -Property @{Text='Medium'; Location='210,130'}),
	(New-Object System.Windows.Forms.Label -Property @{Text='Hard'; Location='352,130'}),
	$diffSlider,
	$updateDiff))

    return @{
        value = $diffSlider
    }
}