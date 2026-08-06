function Exit-App {
    if ($script:isExiting) {
        return
    }
	Start-Sleep -Milliseconds 150
    $passed = Show-ExitChallenge
    Add-Content "$parentDir\logs\debug.log" "Show-ExitChallenge returned: <$passed>"

    if (-not $passed) {
        Add-Content "$parentDir\logs\debug.log" "Exit cancelled"
        return
    }

    $script:isExiting = $true

    if ($script:timer) {
        $script:timer.Stop()
    }
    Cleanup-TrayIcon
    [System.Windows.Forms.Application]::Exit()
}