function Update-ContextMenu {
    param(
        $menu,
        $state
    )

    $isScheduleMode = [bool]$state.scheduled
    $isSessionMode  = -not $isScheduleMode
    $isPaused       = $(Get-PauseData)
    $sessionEnded   = $isSessionMode -and ($state.cycles -le 0)

    Add-Content "$parentDir\logs\debug.log" "$now - scheduled mode: $($state.scheduled)"

    $itemPause = $menu.Items[[Array]::indexof($menu.Items.Text, "Pause for 1 hour")]
    $itemResume = $menu.Items[[Array]::indexof($menu.Items.Text, "End pause now")]
    $itemRestart = $menu.Items[[Array]::indexof($menu.Items.Text, "Start new Session...")]
    $itemProperties = $menu.Items[[Array]::indexof($menu.Items.Text, "Properties")]
    $itemExit = $menu.Items[[Array]::indexof($menu.Items.Text, "Exit")]
    $itemEmergency = $menu.Items[[Array]::indexof($menu.Items.Text, "Emergency unlock (15 min)")]
    $itemShow = $menu.Items[[Array]::indexof($menu.Items.Text, "Show time left")]

    $itemPause.Visible  = -not $isPaused -and -not $sessionEnded
    $itemResume.Visible = $isPaused

    $itemRestart.Visible = $sessionEnded

    $itemProperties.Visible = $true
    $itemExit.Visible       = $true
    $itemEmergency.Visible  = $true
    $itemShow.Visible - $true
}