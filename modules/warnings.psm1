function Time_Warning {
    
    param(
        $workPeriod
    )

    $warnings = @(
        @{second = 0},
        @{third = 0}
    )

    if ($workPeriod -lt 1200 -and $workPeriod -gt 300) {
        $warnings[0]["second"] = 300
    } elseif ($workPeriod -ge 1200) {
        $warnings[0]["second"] = 300
        $warning[0]["third"] = 600
    }

    return($warnings)
}