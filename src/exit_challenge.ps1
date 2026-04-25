Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function New-ExitChallenge($difflvl) {
    $type = Get-Random -InputObject @("parentheses", "twoStep", "comparison", "reverseMemory")

    switch ($type) {
        "parentheses" {
			switch ($difflvl) {
				"Easy" {
					$a = Get-Random -Minimum 2 -Maximum 10
					$b = Get-Random -Minimum 2 -Maximum 10
					$c = Get-Random -Minimum 2 -Maximum 9
				}
				"Medium" {
					$a = Get-Random -Minimum 2 -Maximum 100
					$b = Get-Random -Minimum 2 -Maximum 100
					$c = Get-Random -Minimum 2 -Maximum 9
				}
				"Hard"{
					$a = Get-Random -Minimum 2 -Maximum 1000
					$b = Get-Random -Minimum 2 -Maximum 1000
					$c = Get-Random -Minimum 2 -Maximum 9
				}
			}

            return @{
                Type   = "parentheses"
                Prompt = "What is ($a + $b) * $c ?"
                Answer = (($a + $b) * $c).ToString()
            }
        }

        "twoStep" {
			switch ($difflvl) {
				"Easy" {
					$divisor  = Get-Random -Minimum 2 -Maximum 10
					$quotient = Get-Random -Minimum 2 -Maximum 10
					$addend   = Get-Random -Minimum 1 -Maximum 10
				}
				"Medium" {
					$divisor  = Get-Random -Minimum 2 -Maximum 100
					$quotient = Get-Random -Minimum 2 -Maximum 10
					$addend   = Get-Random -Minimum 1 -Maximum 100
				}
				"Hard"{
					$divisor  = Get-Random -Minimum 2 -Maximum 100
					$quotient = Get-Random -Minimum 2 -Maximum 100
					$addend   = Get-Random -Minimum 1 -Maximum 100
				}
			}

            $dividend = $divisor * $quotient

            return @{
                Type   = "twoStep"
                Prompt = "What is $dividend/$divisor + $addend ?"
                Answer = ($quotient + $addend).ToString()
            }
        }

        "comparison" {
            do {
				switch ($difflvl) {
					"Easy" {
						$b = Get-Random -Minimum 2 -Maximum 5
						$d = Get-Random -Minimum 2 -Maximum 5
						$c = Get-Random -Minimum 2 -Maximum 5
						$a = Get-Random -Minimum 2 -Maximum 5
					}
					"Medium" {
						$b = Get-Random -Minimum 2 -Maximum 8
						$d = Get-Random -Minimum 2 -Maximum 8
						$c = Get-Random -Minimum 2 -Maximum 8
						$a = Get-Random -Minimum 2 -Maximum 8
					}
					"Hard"{
						$b = Get-Random -Minimum 2 -Maximum 12
						$d = Get-Random -Minimum 2 -Maximum 12
						$c = Get-Random -Minimum 2 -Maximum 12
						$a = Get-Random -Minimum 2 -Maximum 12
					}
				}
                $leftValue  = [int][math]::Pow($a, $b)
                $rightValue = [int][math]::Pow($c, $d)
            } while ($leftValue -eq $rightValue -or -not (($a -lt $c -and $b -gt $d) -or ($a -gt $c -and $b -lt $d)))

            $answer = if ($leftValue -gt $rightValue) { "left" } else { "right" }

            return @{
                Type   = "comparison"
                Prompt = "Which is larger? (Ans: 'left' or 'right')`nLeft: $a^$b`nRight: $c^$d"
                Answer = $answer
            }
        }

        "reverseMemory" {
			switch ($difflvl) {
					"Easy" {
						$digits = -join ((1..6) | ForEach-Object { Get-Random -Minimum 0 -Maximum 10 })
					}
					"Medium" {
						$digits = -join ((1..8) | ForEach-Object { Get-Random -Minimum 0 -Maximum 10 })					
					}
					"Hard"{
						$digits = -join ((1..10) | ForEach-Object { Get-Random -Minimum 0 -Maximum 10 })
					}
				}
            $chars = [char[]]$digits
            [array]::Reverse($chars)
            $reversed = -join $chars

            return @{
                Type      = "reverseMemory"
                FlashText = $digits
                Prompt    = "Type the number backwards:"
                Answer    = $reversed
            }
        }
    }
}

function Show-ExitChallenge {
    $exitform = New-Object System.Windows.Forms.Form
    $exitform.Text = "Exit Challenge"
    $exitform.Size = New-Object System.Drawing.Size(360, 220)
    $exitform.StartPosition = "CenterScreen"
    $exitform.FormBorderStyle = "FixedDialog"
    $exitform.MaximizeBox = $false
    $exitform.MinimizeBox = $false
    $exitform.TopMost = $true
    $exitform.Tag = $null

    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(20, 20)
    $label.Size = New-Object System.Drawing.Size(310, 70)
    $label.Font = New-Object System.Drawing.Font("Segoe UI", 10)

    $textbox = New-Object System.Windows.Forms.TextBox
    $textbox.Location = New-Object System.Drawing.Point(20, 105)
    $textbox.Size = New-Object System.Drawing.Size(150, 30)

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "Submit"
    $okButton.Location = New-Object System.Drawing.Point(185, 103)
    $okButton.Size = New-Object System.Drawing.Size(70, 28)
	$okButton.Enabled = $false

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = "Cancel"
    $cancelButton.Location = New-Object System.Drawing.Point(265, 103)
    $cancelButton.Size = New-Object System.Drawing.Size(70, 28)
	
	$exitform.AcceptButton = $okButton
	$exitform.CancelButton = $cancelButton

    $statusLabel = New-Object System.Windows.Forms.Label
    $statusLabel.Location = New-Object System.Drawing.Point(20, 145)
    $statusLabel.Size = New-Object System.Drawing.Size(315, 25)
    $statusLabel.ForeColor = [System.Drawing.Color]::DarkRed

    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 3000

    $initializeChallenge = {
		$timer.Stop()
		$statusLabel.Text = ""
		$textbox.Clear()

		$diffval = Get-Property "exitDifficulty"	
		$exitform.Tag = New-ExitChallenge $difficulty[[int]$diffval]
		$challenge = $exitform.Tag

		if (-not $challenge) {
			return $null
		}

		if ($challenge.Type -eq "reverseMemory") {
			$label.Text = "Memorize this number:`n`n$($challenge.FlashText)"
			$textbox.Enabled = $false
			$okButton.Enabled = $false
			$timer.Start()
		}
		else {
			$label.Text = $challenge.Prompt
			$textbox.Enabled = $true
			$okButton.Enabled = $true
			$textbox.Focus()
		}

		return $null
	}

	$null = $timer.Add_Tick({
		$timer.Stop()
		$challenge = $exitform.Tag
		if (-not $challenge) { return }

		$label.Text = $challenge.Prompt
		$textbox.Enabled = $true
		$okButton.Enabled = $true
		$textbox.Clear()
		$textbox.Focus()
	})

	$null = $okButton.Add_Click({
		$challenge = $exitform.Tag

		if (-not $challenge -or [string]::IsNullOrWhiteSpace($challenge.Answer)) {
			Add-Content "$PSScriptRoot\debug.log" "Submit ignored: no challenge loaded"
			return
		}

		$userAnswer = $textbox.Text.Trim().ToLower()
		$correctAnswer = $challenge.Answer.ToString().Trim().ToLower()

		Add-Content "$PSScriptRoot\debug.log" "User=$userAnswer Correct=$correctAnswer"

		if ($userAnswer -eq $correctAnswer) {
			$exitform.DialogResult = [System.Windows.Forms.DialogResult]::OK
			$exitform.Close()
		}
		else {
			$statusLabel.Text = "Incorrect. New challenge loaded."
			$exitform.Refresh()
			Start-Sleep -Milliseconds 700
			& $initializeChallenge | Out-Null
		}
	})

    $null = $cancelButton.Add_Click({
        $exitform.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $exitform.Close()
    })

    $null = $exitform.Add_FormClosing({
        $timer.Stop()
    })

    $exitform.Controls.AddRange(@(
        $label,
        $textbox,
        $okButton,
        $cancelButton,
        $statusLabel
    ))

    & $initializeChallenge | Out-Null
    $dialogResult = $exitform.ShowDialog()

    $timer.Dispose()
    $exitform.Dispose()

    return ($dialogResult -eq [System.Windows.Forms.DialogResult]::OK)
}

