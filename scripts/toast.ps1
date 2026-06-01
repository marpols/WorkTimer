$ModuleName = 'BurntToast'

Try {
    $null = Get-InstalledModule $ModuleName -ErrorAction Stop
} Catch {
    if ( -not ( Get-PackageProvider -ListAvailable | Where-Object Name -eq "Nuget" ) ) {
        $null = Install-PackageProvider "Nuget" -Scope CurrentUser -Force
    }
    $null = Install-Module $ModuleName -Scope CurrentUser -Force
}
$null = Import-Module $ModuleName -Force