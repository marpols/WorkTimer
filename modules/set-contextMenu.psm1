function Update-ContextMenu {
    param(
        $state
    )

    $isScheduleMode = [bool]$state.scheduled
    $isSessionMode  = -not $isScheduleMode
    $isPaused       = [bool]$state.paused
    $sessionEnded   = $isSessionMode -and ($state.cycles -le 0)

    $itemPause.Visible  = -not $isPaused -and -not $sessionEnded
    $itemResume.Visible = $isPaused

    $itemRestart.Visible = $sessionEnded

    $itemProperties.Visible = $true
    $itemExit.Visible       = $true
    $itemEmergency.Visible  = $true
    $itemShow.Visible - $true
}