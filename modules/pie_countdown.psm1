function Show-CountdownPie {
    param(
        [Parameter(Mandatory)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$DurationSeconds,
        [int]$workPeriod,
        [string]$Title = "Work Timer Countdown",
        [bool]$showTime = $true,
        [bool]$showPie = $true,
        [int]$mainPID = 0,
        [switch]$Wait
    )

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $TargetMonitorIndex = 0
    $TargetScreen = if ($TargetMonitorIndex -lt $Screens.Count) { $Screens[$TargetMonitorIndex] } else { [System.Windows.Forms.Screen]::PrimaryScreen }

    $screenWidth = $screen.Width
    $screenHeight = $screen.Height

    $popupSize = [System.Drawing.Size]::new(
    [int]($screenWidth / 10),
    [int]($screenHeight / 5)
    )

    $form = New-Object System.Windows.Forms.Form -Property @{
    Text            = $Title
    FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
    BackColor       = [System.Drawing.Color]::Gray
    TransparencyKey = [System.Drawing.Color]::Gray
    TopMost         = $true
    ClientSize      = [System.Drawing.Size]::new($popupSize)
    StartPosition   = [System.Windows.Forms.FormStartPosition]::Manual
    MaximizeBox     = $false;
    Opacity = 0.7
}

    $X = $TargetScreen.WorkingArea.Right - $Form.Width
    $Y = $TargetScreen.WorkingArea.Top
    $Form.Location = New-Object System.Drawing.Point($X, $Y)

    # Reduces flickering while repainting.
    $form.GetType().GetProperty(
        "DoubleBuffered",
        [System.Reflection.BindingFlags]"Instance,NonPublic"
    ).SetValue($form, $true)

    $startTime = [datetime]::Now
    $endTime   = $startTime.AddSeconds($DurationSeconds)

    $timer = [System.Windows.Forms.Timer]::new()
    $timer.Interval = 50
    
    $form.Add_Paint({
        param($sender, $eventArgs)


        $graphics = $eventArgs.Graphics

        $remaining = [math]::Max(
                0,
                ($endTime - [datetime]::Now).TotalSeconds
            )

        if ($showPie){
            $graphics.SmoothingMode =
                [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

            $fractionRemaining = $remaining / $workPeriod
            $sweepAngle = [single](360 * $fractionRemaining)

            $pieBounds = [System.Drawing.RectangleF]::new(
                $form.ClientSize.Width/4,
                $form.ClientSize.Height/6,
                $form.ClientSize.Width/2,
                $form.ClientSize.Width/2
            )


            # Background circle.
            $backgroundBrush = [System.Drawing.SolidBrush]::new(
                [System.Drawing.Color]::Gainsboro
            )

            # Remaining-time segment.
            
            if ($remaining -le 60){
                    $countdownBrush = [System.Drawing.SolidBrush]::new(
                    [System.Drawing.Color]::red
                )
            } else {
                    $countdownBrush = [System.Drawing.SolidBrush]::new(
                    [System.Drawing.Color]::CornflowerBlue
                )
            }

            $graphics.FillEllipse($backgroundBrush, $pieBounds)

            if ($sweepAngle -gt 0) {
                # Start at 12 o'clock and decrease clockwise.
                $graphics.FillPie(
                    $countdownBrush,
                    $pieBounds,
                    -90,
                    $sweepAngle
                )
            }
        }

        if ($showTime){
            $remainingRounded = [math]::Ceiling($remaining)
            $timeText = "{0:mm\:ss}" -f [timespan]::FromSeconds(
                $remainingRounded
            )

            if (-not $showPie){
                $fontSize = [Math]::Max(
                    10,
                    [int]([Math]::Min($form.ClientSize.Width, $form.ClientSize.Height) / 5)
                    )
                $Y_pos = $form.ClientSize.Height/4
            } else {
                $fontSize = [Math]::Max(
                    10,
                    [int]([Math]::Min($form.ClientSize.Width, $form.ClientSize.Height) / 10) 
                )
                $Y_pos = $form.ClientSize.Height/2 + 50
            }

            $font = [System.Drawing.Font]::new(
                "Segoe UI",
                $fontSize,
                [System.Drawing.FontStyle]::Bold
            )

            if($remaining -le 60){
                $textBrush = [System.Drawing.SolidBrush]::new(
                    [System.Drawing.Color]::red
                )
            } else {
                if ($(Get-SysTheme) -eq "Light"){
                    $textBrush = [System.Drawing.SolidBrush]::new(
                        [System.Drawing.Color]::Gainsboro
                    )
                } else {
                    $textBrush = [System.Drawing.SolidBrush]::new(
                        [System.Drawing.Color]::black
                    )
                }
            }

            $textSize = $graphics.MeasureString($timeText, $font)

            $graphics.DrawString(
                $timeText,
                $font,
                $textBrush,
                ($form.ClientSize.Width - $textSize.Width) / 2,
                $Y_pos
            )

            $textBrush.Dispose()
            $font.Dispose()

        }

        if ($showPie){
            $backgroundBrush.Dispose()
            $countdownBrush.Dispose()
        }
    }.GetNewClosure())

    $timer.Add_Tick({
        if ([datetime]::Now -ge $endTime) {
            $timer.Stop()
            $form.Invalidate()

            # Close automatically when finished.
            $form.Close()
        }
        else {
            $form.Invalidate()
        }

        if ($mainPID -gt 0) {
            if (-not (Get-Process -Id $mainPID -ErrorAction SilentlyContinue)) {
            $timer.Stop()
            $form.Close()
            return
        }
    }
    }.GetNewClosure())


    $form.Add_FormClosed({
        $timer.Stop()
        $timer.Dispose()
    }.GetNewClosure())

   # One mutable object shared by all event handlers.
    $dragState = @{
        IsDragging = $false
        StartMouse = [System.Drawing.Point]::Empty
        StartForm  = [System.Drawing.Point]::Empty
    }

    $form.Add_MouseDown({
        param($sender, $eventArgs)

        if ($eventArgs.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
            $dragState.IsDragging = $true
            $dragState.StartMouse = [System.Windows.Forms.Cursor]::Position
            $dragState.StartForm  = $form.Location

            $form.Capture = $true
        }
    }.GetNewClosure())

    $form.Add_MouseMove({
        param($sender, $eventArgs)

        if ($dragState.IsDragging) {
            $currentMouse = [System.Windows.Forms.Cursor]::Position

            $form.Location = [System.Drawing.Point]::new(
                $dragState.StartForm.X +
                    ($currentMouse.X - $dragState.StartMouse.X),

                $dragState.StartForm.Y +
                    ($currentMouse.Y - $dragState.StartMouse.Y)
            )
        }
    }.GetNewClosure())

    $form.Add_MouseUp({
        param($sender, $eventArgs)

        if ($eventArgs.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
            $dragState.IsDragging = $false
            $form.Capture = $false
        }
    }.GetNewClosure())

    $form.Add_MouseCaptureChanged({
        if (-not $form.Capture) {
            $dragState.IsDragging = $false
        }
    }.GetNewClosure())

    $form.ShowInTaskbar = $false

    $timer.Start()
    $form.Invalidate()

    if ($Wait) {
            [void]$form.ShowDialog()
            $form.TopMost = $true
    } else {
            [void]$form.Show()
            Write-Output -NoEnumerate $form
    }


}

