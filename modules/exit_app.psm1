function Exit-App {
    param(
        $exitChallenge
    )

    if ($script:isExiting) {
        return
    }

    if ($exitChallenge) {
        Start-Sleep -Milliseconds 150
        $passed = Show-ExitChallenge
        Add-Content "$parentDir\logs\debug.log" "Show-ExitChallenge returned: <$passed>"

        if (-not $passed) {
            Add-Content "$parentDir\logs\debug.log" "Exit cancelled"
            return
        }
    }

    $script:isExiting = $true

    if ($script:timer) {
        $script:timer.Stop()
        $script:timer.Dispose()
        $script:timer = $null
    }

    if ($script:cycles) {
        $script:cycles.Stop()
        $script:cycles.Dispose()
        $script:cycles = $null
    }
    
    if (
        $script:pieCountdown -and
        -not $script:pieCountdown.IsDisposed
    ) {
        $script:pieCountdown.Close()
        $script:pieCountdown = $null
    }

    if ($script:controlTimer) {
        $script:controlTimer.Stop()
        $script:controlTimer.Dispose()
        $script:controlTimer = $null
    }
    
    Cleanup-TrayIcon

    if ($script:mutex) {
			$script:mutex.ReleaseMutex()
			$script:mutex.Dispose()
			$script:mutex = $null
    }
  
    [System.Windows.Forms.Application]::Exit()
}