Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$Script:Seconds = 120 

$screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$screenArea = [System.Windows.Forms.Screen]::AllScreens
$TargetMonitorIndex = 0
$TargetScreen = if ($TargetMonitorIndex -lt $Screens.Count) { $Screens[$TargetMonitorIndex] } else { [System.Windows.Forms.Screen]::PrimaryScreen }

$screenWidth = $screen.Width
$screenHeight = $screen.Height

$popupSize = [System.Drawing.Size]::new(
[int]($screenWidth / 8),
[int]($screenHeight / 8)
)

# --- UI Layout ---
$Form = New-Object System.Windows.Forms.Form -Property @{
    Text = "Work Timer";
    Size = $popupSize;
    StartPosition = "Manual";
    Left = 2200;
    Top = $screenArea.Y;
    FormBorderStyle = "FixedDialog";
    MaximizeBox = $false;
    TopMost = $true;
    BackColor = "#72BBFF"
}

$X = $TargetScreen.WorkingArea.Right - $Form.Width
$Y = $TargetScreen.WorkingArea.Top
$Form.Location = New-Object System.Drawing.Point($X, $Y)

$fontSize = [Math]::Max(
        10,
        [int]([Math]::Min($form.ClientSize.Width, $form.ClientSize.Height) / 2)
    )

$Label = New-Object System.Windows.Forms.Label -Property @{
    Location = '10,20'; Size = '260,50'; Font = "Segoe UI, $($fontsize)"; TextAlign = "MiddleCenter"; Dock = "Fill"
}

# --- Logic ---
$Timer = New-Object System.Windows.Forms.Timer
$Timer.Interval = 1000
$UpdateLabel = { $Label.Text = [TimeSpan]::FromSeconds($Script:Seconds).ToString("hh\:mm\:ss") }
$UpdateLabel.Invoke() # Initial display

$Timer.Add_Tick({
    if ($Script:Seconds -gt 60) {
        $Script:Seconds--
        $UpdateLabel.Invoke()
    } else {
        $Timer.Stop()
        $Timer.Dispose()
        $Form.Dispose()
    }
})

$Form.Controls.AddRange(@($Label))

$Timer.Start()

# Cleanup
$Form.Add_FormClosing({ $Timer.Stop(); $Timer.Dispose() })
$Form.ShowDialog() | Out-Null
