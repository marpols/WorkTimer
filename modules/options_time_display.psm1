function display-options {
    param(
        $page,
        $properties
    )

    $pieChartClr = ConvertTo-DrawingColor `
    -Colour $properties.pieChartClr `
    -Default ([System.Drawing.Color]::CornflowerBlue)

    $textDispClr = ConvertTo-DrawingColor `
    -Colour $properties.textDispClr `
    -Default ([System.Drawing.Color]::Black)

    #Piechart
	$pieCheck = New-Object System.Windows.Forms.Checkbox -Property @{
		Text = "Piechart";
		Location='150,10';
		Autosize=$true;
		Checked = $properties.showPie
	}
	$pieTooltip = New-Object System.Windows.Forms.ToolTip
	$pieTooltip.SetToolTip($pieCheck, "Display a pie chart showing the elapsed time in the work session")
	
	#Time Display
	$timedispCheck = New-Object System.Windows.Forms.Checkbox -Property @{
		Text = "Countdown";
		Location='250,10';
		Autosize=$true;
		Checked = $properties.showTime
	}
	$timedispTooltip = New-Object System.Windows.Forms.ToolTip
	$timedispTooltip.SetToolTip($timedispCheck, "Display a countdown of the time left in the work session")

	$pieClrBtn = New-Object System.Windows.Forms.Button -Property @{
		Text='pie chart';
		Location=[System.Drawing.Point]::new(300, 110);
		Autosize=$true
	}

    $countdownClrBtn = New-Object System.Windows.Forms.Button -Property @{
		Text='countdown';
		Location=[System.Drawing.Point]::new(300, 205);
		Autosize=$true
	}

    $resetBtn = New-Object System.Windows.Forms.Button -Property @{
		Text='Reset';
		Location=[System.Drawing.Point]::new(10, 10);
		Autosize=$true
	}

    $previewBtn = New-Object System.Windows.Forms.Button -Property @{
		Text='Preview';
		Location=[System.Drawing.Point]::new(380, 10);
		Autosize=$true
	}

    $Page.Tag = @{
        showPie  = $pieCheck.Checked
        showTime = $timedispCheck.Checked
        pieClr   = $pieChartClr
        txtClr   = $textDispClr

        pieCheck        = $pieCheck
        timeCheck       = $timedispCheck
        pieClrBtn       = $pieClrBtn
        countdownClrBtn = $countdownClrBtn
    }

    #Pie Chart
    $pieChartHandler = {
        param($sender, $e)

        if (-not $sender.Tag.showPie -and $sender.Tag.showTime) {
            return
        }

        $g = $e.Graphics
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

        $width  = [single]($sender.ClientSize.Width / 4)
        $height = [single]($sender.ClientSize.Width / 4)

        $pieBounds = [System.Drawing.RectangleF]::new(
            [single]($sender.ClientSize.Width / 4),
            [single]($sender.ClientSize.Height / 4),
            $width,
            $height
        )

        $backgroundBrush = [System.Drawing.SolidBrush]::new(
            [System.Drawing.Color]::Gainsboro
        )

        if ($sender.Tag.showPie) {
            $pieColor = $sender.Tag.pieClr
        }
        else {
            $pieColor = Get-GreyedColour -Colour $sender.Tag.pieClr
        }

        $countdownBrush = [System.Drawing.SolidBrush]::new($pieColor)

        $g.FillEllipse($backgroundBrush, $pieBounds)

        $g.FillPie(
            $countdownBrush,
            $pieBounds,
            -90,
            [single]270
        )

        

        $backgroundBrush.Dispose()
        $countdownBrush.Dispose()
    }

    #Countdown Text
    $countdownHandler = {
        param($sender, $e)

        $showPie  = $sender.Tag.showPie
        $showTime = $sender.Tag.showTime

        if (-not $showTime -and $showPie) {
            return
        }

        $g = $e.Graphics
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

        $timetext = "12:34"

        if ($showPie -or (-not $showPie -and -not $showTime)) {
            $fontSize = [Math]::Max(
                5,
                [int]([Math]::Min(
                    $sender.ClientSize.Width,
                    $sender.ClientSize.Height
                ) / 10)
            )
            $Y_pos = $sender.ClientSize.Height / 3 + 100
        }
        else {
            $fontSize = [Math]::Max(
                10,
                [int]([Math]::Min(
                    $sender.ClientSize.Width,
                    $sender.ClientSize.Height
                ) / 5)
            )
            $Y_pos = $sender.ClientSize.Height / 3

        }

        $font = [System.Drawing.Font]::new(
            "Segoe UI",
            $fontSize,
            [System.Drawing.FontStyle]::Bold
        )

        if (-not $showPie -and -not $showTime) {
            $textColor = Get-GreyedColour -Colour $sender.Tag.txtClr
            
        }
        else {
            $textColor = $sender.Tag.txtClr
        }

        $textBrush = [System.Drawing.SolidBrush]::new($textColor)

        $textSize = $g.MeasureString($timetext, $font)

        $g.DrawString(
            $timetext,
            $font,
            $textBrush,
            ($sender.ClientSize.Width - $textSize.Width) / 3,
            $Y_pos
        )

        $textBrush.Dispose()
        $font.Dispose()
    }

    $Page.Add_Paint($pieChartHandler)
    $Page.Add_Paint($countdownHandler)


    $pieCheck.Add_CheckedChanged({
        param($sender, $e)

        $page = $sender.Parent

        $page.Tag.showPie = $sender.Checked

        Update-DisplayOptions -Page $page
    })

    $timedispCheck.Add_CheckedChanged({
        param($sender, $e)

        $page = $sender.Parent

        $page.Tag.showTime = $sender.Checked

        Update-DisplayOptions -Page $page
    })

    $resetBtn.Add_Click({
        param($sender, $e)
        $page = $sender.Parent

        $page.Tag.pieClr = [System.Drawing.Color]::CornflowerBlue
        $page.Tag.txtClr = [System.Drawing.Color]::Black
        $page.Invalidate()


    })

    $previewBtn.Tag = @{
        PreviewForm = $null
    }

    $previewBtn.Add_Click({
        param($sender, $e)
        $page = $sender.Parent

        if ($sender.Tag.PreviewForm -and -not $sender.Tag.PreviewForm.IsDisposed) {
            $sender.Tag.PreviewForm.Close()
            $sender.Tag.PreviewForm = $null
            $sender.Text = "Preview"
        } else {
        $sender.Tag.PreviewForm = Show-CountdownPie `
            -DurationSeconds 90 `
            -workPeriod 120 `
            -showPie $page.Tag.showPie `
            -showTime $page.Tag.showTime `
            -pieColour $page.Tag.pieClr `
            -txtColour $page.Tag.txtclr

        $sender.Text = "Close preview"
        }

        $page.Invalidate()
        
    }
    )

    $pieClrBtn.Add_Click({
        param($sender, $e)

        $page = $sender.Parent

        $colorDialog = [System.Windows.Forms.ColorDialog]::new()

        if ($null -ne $page.Tag.pieClr) {
            $colorDialog.Color = $page.Tag.pieClr
        }

        if (
            $colorDialog.ShowDialog() -eq
            [System.Windows.Forms.DialogResult]::OK
        ) {
            $page.Tag.pieClr = $colorDialog.Color
            $page.Invalidate()
        }

        $colorDialog.Dispose()
    })

    $countdownClrBtn.Add_Click({
        param($sender, $e)

        $page = $sender.Parent

        $colorDialog = [System.Windows.Forms.ColorDialog]::new()

            if ($null -ne $page.Tag.txtClr) {
                $colorDialog.Color = $page.Tag.txtClr
            }

            if (
                $colorDialog.ShowDialog() -eq
                [System.Windows.Forms.DialogResult]::OK
            ) {
                $page.Tag.txtClr = $colorDialog.Color
                $page.Invalidate()
            }

            $colorDialog.Dispose()
    })


    $controls = (@($pieCheck, $pieClrBtn, $timedispCheck, $countdownClrBtn, $resetBtn, $previewBtn))
	$Page.Controls.AddRange($controls)

    return @{
        vals = $Page.Tag
        preview = $previewBtn.Tag
    }
}


function Get-GreyedColour {
    param(
        [System.Drawing.Color]$Colour,
        [double]$Amount = 0.7
    )

    $grey = 180

    $r = [int]($Colour.R * (1 - $Amount) + $grey * $Amount)
    $g = [int]($Colour.G * (1 - $Amount) + $grey * $Amount)
    $b = [int]($Colour.B * (1 - $Amount) + $grey * $Amount)

    return [System.Drawing.Color]::FromArgb($r, $g, $b)
}

function ConvertTo-DrawingColor {
    param(
        $Colour,
        [System.Drawing.Color]$Default = [System.Drawing.Color]::CornflowerBlue
    )

    if ($null -eq $Colour) {
        return $Default
    }

    # Already a real System.Drawing.Color
    if ($Colour -is [System.Drawing.Color]) {
        return $Colour
    }

    # Hex/string colour such as "#6495ED" or "CornflowerBlue"
    if ($Colour -is [string]) {

        if ($Colour -match '^#[0-9A-Fa-f]{6}$') {
            return [System.Drawing.ColorTranslator]::FromHtml($Colour)
        }

        return [System.Drawing.Color]::FromName($Colour)
    }

    # Deserialized colour object / PSCustomObject / hashtable
    if (
        $null -ne $Colour.R -and
        $null -ne $Colour.G -and
        $null -ne $Colour.B
    ) {
        $alpha = if ($null -ne $Colour.A) {
            [int]$Colour.A
        }
        else {
            255
        }

        return [System.Drawing.Color]::FromArgb(
            $alpha,
            [int]$Colour.R,
            [int]$Colour.G,
            [int]$Colour.B
        )
    }

    return $Default
}

function Update-DisplayOptions {
    param(
        [System.Windows.Forms.Control]$Page
    )

    $state = $Page.Tag

    if ($state.showPie -and $state.showTime) {

        $state.pieClrBtn.Visible = $true
        $state.pieClrBtn.Enabled = $true

        $state.countdownClrBtn.Visible = $true
        $state.countdownClrBtn.Enabled = $true

        $state.countdownClrBtn.Location =
            [System.Drawing.Point]::new(
                300,
                205
            )
    }
    elseif ($state.showPie) {

        $state.pieClrBtn.Visible = $true
        $state.pieClrBtn.Enabled = $true

        $state.countdownClrBtn.Visible = $false
    }
    elseif ($state.showTime) {

        $state.pieClrBtn.Visible = $false

        $state.countdownClrBtn.Visible = $true
        $state.countdownClrBtn.Enabled = $true

        $state.countdownClrBtn.Location =
            [System.Drawing.Point]::new(
                300,
                130
            )

    } else {

        $state.pieClrBtn.Visible = $true
        $state.pieClrBtn.Enabled = $false

        $state.countdownClrBtn.Visible = $true
        $state.countdownClrBtn.Enabled = $false

        $state.countdownClrBtn.Location =
            [System.Drawing.Point]::new(
                300,
                205
            )
    }

    $Page.Invalidate()
}