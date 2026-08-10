$PersonalisePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"

function Get-SysTheme {
    $appsUseLight = (Get-ItemProperty -Path $PersonalisePath -Name "AppsUseLightTheme" -ErrorAction SilentlyContinue).AppsUseLightTheme
    if ($appsUseLight -eq 0) { return "Dark" }
    return "Light"
}