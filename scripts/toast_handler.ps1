param(
    [string]$Uri
)

$ParentPath = Split-Path $PSScriptRoot

Add-Content "C:\WorkTimer\logs\toast_handler_debug.log" `
    "$(Get-Date -Format o) ParentPath = [$ParentPath]"

Import-Module "$ParentPath\modules\set_cycles.psm1"

Add-Content "C:\WorkTimer\logs\toast_handler_debug.log" `
    "$(Get-Date -Format o) handler started; Uri=[$Uri]"

$uriObj = [uri]$Uri
$action = $uriObj.Host

Add-Content "C:\WorkTimer\logs\toast_handler_debug.log" `
    "$(Get-Date -Format o) action=[$action]"

switch ($action) {

    "setcycles" {
        Add-Content "C:\WorkTimer\logs\toast_handler_debug.log" "$(Get-Date -Format o) - setcycles called"
        Set-Cycles
    }

    "start" {
        try {
            $event = [System.Threading.EventWaitHandle]::OpenExisting(
                "WorkTimerStartCycles"
            )

            $event.Set() | Out-Null
            $event.Dispose()
        }
        catch {
            Add-Content "$ParentPath\logs\errors.log" `
                "$(Get-Date -Format o) Start event failed: $($_.Exception.Message)"
        }
    }

    "exit"{
        try {
            $event = [System.Threading.EventWaitHandle]::OpenExisting(
                "WorkTimerExit"
            )

            $event.Set() | Out-Null
            $event.Dispose()
        }
        catch {
            Add-Content "$ParentPath\logs\errors.log" `
                "$(Get-Date -Format o) Exit event failed: $($_.Exception.Message)"
        }
    }

}