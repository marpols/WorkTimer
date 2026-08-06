function Set-ControlsVisible {
    param(
        [bool]$Visible,
        [System.Windows.Forms.Control[]]$Controls
    )
    foreach ($control in $Controls) {
        if ($null -ne $control) {
            $control.Visible = $Visible
        }
    }
}

function Set-ControlsEnabled {
    param(
        [bool]$Enable,
        [System.Windows.Forms.Control[]]$Controls
    )
    foreach ($control in $Controls) {
        if ($null -ne $control) {
            $control.Enabled = $Enable
        }
    }
}