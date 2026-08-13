function get-theme {
    $RegistryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    $AppsUseLightTheme = Get-ItemProperty -Path $RegistryPath -Name "AppsUseLightTheme" -ErrorAction SilentlyContinue

    $IsDarkMode = $false
    if ($null -ne $AppsUseLightTheme -and $AppsUseLightTheme.AppsUseLightTheme -eq 0) {
        $IsDarkMode = $true
    }

    if ($IsDarkMode) {
        $FormBgColor   = [System.Drawing.Color]::FromArgb(32, 32, 32)
        $ControlBgColor= [System.Drawing.Color]::FromArgb(45, 45, 45)
        $TextColor     = [System.Drawing.Color]::White
    } else {
        $FormBgColor   = [System.Drawing.Color]::FromArgb(243, 243, 243)
        $ControlBgColor= [System.Drawing.Color]::White
        $TextColor     = [System.Drawing.Color]::Black
    }

    return @{
        bg = $FormBgColor
        control = $ControlBgColor
        txt = $TextColor
    }
}