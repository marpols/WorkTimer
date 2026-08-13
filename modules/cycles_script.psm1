function Start-CyclesScript {

     if ($script:cycles) {
        if ($script:cycles.Enabled) {
            return
        }

        $script:cycles.Start()
        return
    }

    # Timer loop
    $script:cycles = New-Object System.Windows.Forms.Timer
    $script:cycles.Interval = $tbfrelock

    $script:cycles.Add_Tick({
        $state = Load-State
        $now = Get-Now
        $lastTick = [datetime]$state.lastTick
        $elapsed = [math]::Max(0, [int]($now - $lastTick).TotalSeconds)

        if ($state.cycles -gt 0){

            #start countdown if not created when script started
            $createTimeDisplay = (-not $state.firstCountdown -and ($state.showPie -or $state.showTime))
            If($createTimeDisplay){
                $script:pieCountdown = Show-CountdownPie `
                            -DurationSeconds $state.remainingSeconds `
                            -workPeriod $state.workPeriod `
                            -showPie $state.showPie `
                            -showTime $state.showTime `
                            -mainPID $mainPID
                $state.firstCountdown = $true
                Save-State $state
            }

            #check if emergency unlock
            if ($state.emergencyUntil) {
                $emergencyUntil = [datetime]$state.emergencyUntil
                if ((Get-Date) -lt $emergencyUntil) {
                    $state.lastTick = (Get-Date).ToString("o")
                    Save-State $state
                    return
                } else {
                    $state.emergencyUntil = $null
                }
            }

            #check pause active
            if (Pause-Active) {
                $state.lastTick = $now.ToString("o")
                Save-State $state
                return
            }
            
            #check idle
            if ($(Is-Idle 3) -and (-not $state.cooldown)){
                if (-not $state.warnedIdle){
                    Toast-Notification `
                        -msg "Computer has been idle for 3 minutes. Pausing timer." `
                        -header "Work Timer"
                    $state.warnedIdle = $true
                }
                if (Is-Idle 10){
                    $state.extendedIdle = $true
                }
                $state.lastTick = $now.ToString("o")
                Save-State $state
                return
            } else {
                $state.warnedIdle = $false
            }

            #in cooldown/break
            if ($state.cooldownUntil) {
                $cooldownUntil = [datetime]$state.cooldownUntil
                $lastUnlock = [datetime]$state.lastUnlock
                
                if ($now -lt $cooldownUntil) { #still in break period
                    $state.lastTick = $now.ToString("o")
                    Save-State $state
                    Lock-PC
                    return
                } else { #break over

                    #unlock when end of break in between ticks
                    if ($lastUnlock -ge $lastTick -or $lastUnlock -ge $cooldownUntil){
                        $state = Update-Pom $state
                        $updated = Reset-State
                        $state = Load-State
                        $state.lastTick = $now.ToString("o")

					    if ($state.pomodoro -and $updated){
						        $state = Update-Cycle $state
					        } elseif (-not $state.pomodoro){
						        $state = Update-Cycle $state
					        }	
				    
                        Save-State $state

                        if ($state.cycles -le 0){
                            return
                        }

                        if ($state.showPie -or $state.showTime) {
                            $script:pieCountdown = Show-CountdownPie `
                                -DurationSeconds $state.workPeriod `
                                -workPeriod $state.workPeriod `
                                -showPie $state.showPie `
                                -showTime $state.showTime `
                                -mainPID $mainPID
                        }

                        $msg = "Session: $($state.numCycles - $state.cycles + 1) of $($state.numCycles)`n"

                        if ($state.pomodoro){
                            Pom-Message -state $state -msg $msg
                        } else {
                            Timer-Message -state $state -msg $msg
                        }
                        Add-Content "$parentDir\logs\debug.log" "$now - Reset from work_timer.ps1 check"

                        $state.cooldownUntil = $null

                        return
                    }

                    $state.cooldownUntil = $null
                }
            }
            
            $state.remainingSeconds -= $elapsed

            if($state.unlockReset){
                if ($state.showPie -or $state.showTime) {
                        $script:pieCountdown = Show-CountdownPie `
                            -DurationSeconds $state.remainingSeconds `
                            -workPeriod $state.workPeriod `
                            -showPie $state.showPie `
                            -showTime $state.showTime `
                            -mainPID $mainPID
                    }
                $state.unlockReset = $false
            }

            #reminders
            $reminderChime = $state.timeReminderChime

            if ($state.remainingSeconds -lt 0) { $state.remainingSeconds = 0 }

            $warnings = Warning-Triggers -workPeriod $state.workPeriod
            $oneminWarning = -not $state.warnedoneMin `
                -and ($state.remainingSeconds -le 60) `
                -and ($state.remainingSeconds -gt 0)
            $secondPopup = -not $state.secondWarning `
                -and ($state.remainingSeconds -le $warnings.second) `
                -and ($state.remainingSeconds -gt 60)
            $thirdPopup = -not $state.thirdWarning `
                -and ($state.remainingSeconds -le $warnings.third) `
                -and $state.remainingSeconds -gt $warnings.second
            

            if ($thirdPopup) {
                if($state.reminderPopups){
                Toast-Notification `
                    "$(Get-RemainingText $state.remainingSeconds $true) left." `
                    -soundFile $reminderChime `
                    -chime $state.sounds
                } elseif ($state.sounds) {
                    Play-Chime $reminderChime
                }
                $state.thirdWarning = $true
            }

            if ($secondPopup) {
                if($state.reminderPopups){
                Show-Popup `
                    -text "$(Get-RemainingText $state.remainingSeconds $true) left.`nStart wrapping up." `
                    -soundfile $reminderChime `
                    -chime $state.sounds
                } elseif ($state.sounds) {
                    Play-Chime $reminderChime
                }
                $state.secondWarning = $true
            }
            
            #1 minute warning
            if ($oneminWarning) {

                #start toast notification as seperate process
                if($state.reminderPopups){
                    Show-Popup -text "1 minute left!" -soundfile $reminderChime -chime $state.sounds
                } elseif (-not $state.showPie -and -not $state.showTime){
                    Start-Countdown `
                        -duration 1 `
                        -chime $false `
                        -msg "1 minute to go!" `
                        -msg2 "Save your work and write next steps (leave some breadcrumbs)" `
                        -barTitle "Time until break:" `
                        -endMsg "You did it! Time for a break!"
                }

                $state.warnedoneMin = $true
            }

            if (-not $state.cooldown -and $state.remainingSeconds -le 0) {
                if ($state.pomodoro){
                    if($state.pomNum -gt 1){
                        $text = "Short Break:"
                        $lockoutTime = $state.shortBreak
                    } else {
                        $text = "Long Break:"
                        $lockoutTime = $state.lockOut
                    }
                } else {
                    $text = "Break:"
                    $lockoutTime = $state.lockOut
                }
                $breakUntil = $now.AddMinutes($lockoutTime)
                Show-Popup `
                    -text "Time is up! The computer will lock now.`n$text $(Get-remainingText ($lockoutTime*60) $true)`nYou can come back at $($breakUntil.ToString(`"HH:mm`"))" `
                    -soundFile $state.workEndChime `
                    -chime $state.sounds
                $state.cooldownUntil = $breakUntil.ToString("o")
                $state.cooldown = $true

                Lock-PC
                
                Start-Countdown -duration $lockoutTime -endChime $state.breakEndChime -chime $state.sounds
                
            }

            $state.lastTick = $now.ToString("o")
            Save-State $state

        } else {
            $script:cycles.Stop()
            Cycles-notification -msg "All Sessions Completed!" -msg2 "Great Job! 🎉" -button1_msg "Start Again with $($state.numCycles) Sessions" -button2_msg "Set New Number of Sessions" -exit $true
            $script:cycles.Dispose()
            $script:cycles = $null
        }
    })
    $script:cycles.Start()
}
