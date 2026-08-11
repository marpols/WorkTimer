function HM-S {
	param(
		$hours,
		$minutes
	)
	return 60 * (60 * $hours + $minutes)
}

function S-HM {
	param(
		$seconds
	)
	$value = $seconds/3600
	$hours = [Math]::Truncate($value)
	$minutes = ($value-$hours)*60
	return $hours, $minutes
}