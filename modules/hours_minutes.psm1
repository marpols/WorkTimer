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