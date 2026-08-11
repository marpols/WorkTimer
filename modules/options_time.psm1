function time-Options {
    param(
            $Page,
            $mainform,
            $Properties
        )
    
    $timePickerStart = New-Object System.Windows.Forms.DateTimePicker -Property @{Format='Custom'; CustomFormat = "HH:mm"; Value = Str-to-Date($properties.startTime); ShowUpDown=$true; Location='240,25'; Size='150,20'}
	$timePickerEnd = New-Object System.Windows.Forms.DateTimePicker -Property @{Format='Custom'; CustomFormat = "HH:mm"; Value = Str-to-Date($properties.endTime); ShowUpDown=$true; Location='240,65'; Size='150,20'}
	$updateTime = New-Object System.Windows.Forms.Button -Property @{Text='Set schedule'; Location='240,90'; Autosize=$true}
	
	$updateTime.Tag = @{
		start = $timePickerStart
		end = $timePickerEnd
		properties = $Properties
		mainform = $mainform
	}
	
	$updateTime.Add_Click({
		param($sender, $e)
		$start = $sender.Tag.start
		$end = $sender.Tag.End
		$properties = $sender.Tag.properties
		$mainform = $sender.Tag.mainform

		if(Check-Hours $start.Value $end.Value $mainform){
			$mainform.Refresh()
			$mainform.Activate()
		} else {
			$properties.startTime = $start.Value.ToString("HH:mm")
			$properties.endTime = $end.Value.ToString("HH:mm")
			Save-Properties $properties
			Toast-Notification -msg "Work Timer will now be active between $($start.Value.ToString("HH:mm")) and $($end.Value.ToString("HH:mm")).`nChanges will take effect on restart." -header "Work Timer Update"
		}
	})
	$Page.Controls.AddRange(@($timePickerStart, $timePickerEnd, $updateTime, 
	    (New-Object System.Windows.Forms.Label -Property @{Text='Start Time:'; Location='240,10'}),
        (New-Object System.Windows.Forms.Label -Property @{Text='End Time:'; Location='240,50'})
     )
    )

    return @{
        start = $timePickerStart
        end = $timePickerEnd
        btn = $updateTime
    }
}