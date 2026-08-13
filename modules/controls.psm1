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

function Set-ControlsEnabled2 {
    param(
        [bool]$Enable,
        [System.Windows.Forms.Control[]]$Controls
    )
    foreach ($control in $Controls) {
        if ($null -ne $control) {
            if (($Enable -and -not $control.Enabled) -or (-not $Enable -and $control.Enabled)){
                $control.Enabled = $Enable
            }
        }
    }
}

function Set-TabVisible {
    param(
        [System.Windows.Forms.TabControl]$TabControl,
        [System.Windows.Forms.TabPage[]]$TabOrder,
        [bool]$Visible,
        [System.Windows.Forms.TabPage[]]$Tabs
    )

    foreach ($tab in $Tabs) {
        if ($null -eq $tab) {
            continue
        }

        if ($Visible -and -not $TabControl.TabPages.Contains($tab)) {
            $TabControl.TabPages.Add($tab)
        }
        elseif (-not $Visible -and $TabControl.TabPages.Contains($tab)) {
            $TabControl.TabPages.Remove($tab)
        }
    }

    Set-TabOrder -TabControl $TabControl -TabOrder $TabOrder
}

function Set-TabVisible {
    param(
        [System.Windows.Forms.TabControl]$TabControl,
        [System.Windows.Forms.TabPage[]]$TabOrder,
        [bool]$Visible,
        [System.Windows.Forms.TabPage[]]$Tabs
    )

    foreach ($tab in $Tabs) {

        if ($null -eq $tab) {
            continue
        }

        if ($Visible -and -not $TabControl.TabPages.Contains($tab)) {

            $i = Get-TabIndex `
                -CurTabs $TabControl.TabPages `
                -OrgTabs $TabOrder `
                -Tab $tab

            $TabControl.TabPages.Insert($i, $tab)

        }
        elseif (-not $Visible -and $TabControl.TabPages.Contains($tab)) {

            $TabControl.TabPages.Remove($tab)
        }
    }
}

function Get-TabIndex {
    param(
        [System.Windows.Forms.TabPage[]]$CurTabs,
        [System.Windows.Forms.TabPage[]]$OrgTabs,
        [System.Windows.Forms.TabPage]$Tab
    )

    $targetIndex = [Array]::IndexOf($OrgTabs, $Tab)

    $insertIndex = 0

    foreach ($t in $CurTabs) {
        $currentIndex = [Array]::IndexOf($OrgTabs, $t)

        if ($currentIndex -lt $targetIndex) {
            $insertIndex++
        }
    }

    return $insertIndex
}
