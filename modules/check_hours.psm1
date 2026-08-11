function Check-Hours {
	param(
		$start,
		$end,
		$form
	)
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