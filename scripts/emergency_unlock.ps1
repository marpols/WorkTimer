Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName PresentationFramework


. "$PSScriptRoot\global_vars.ps1"
Import-Module "$parentDir\modules\utils.ps1" -Function "Load-State", "Save-State"

$state = Load-State

if ($state.emergencyUsed) {
    [System.Windows.MessageBox]::Show("Emergency unlock has already been used today.", "Work Timer") | Out-Null
    exit
}

$answer = [Microsoft.VisualBasic.Interaction]::InputBox(
    "Type EMERGENCY to unlock for 15 minutes.",
    "Emergency Unlock",
    ""
)

if ($answer -ceq "EMERGENCY") {
    $state.emergencyUsed = $true
    $state.emergencyUntil = (Get-Date).AddMinutes(15).ToString("o")
    Save-State $state
    [System.Windows.MessageBox]::Show("Emergency unlock granted for 15 minutes.", "Work Timer") | Out-Null
} else {
    [System.Windows.MessageBox]::Show("Emergency unlock cancelled.", "Work Timer") | Out-Null
}