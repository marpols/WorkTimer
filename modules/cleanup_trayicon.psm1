function Cleanup-TrayIcon {
    if ($script:notifyIcon) {
        $script:notifyIcon.Visible = $false
		if ($script:notifyIcon.ContextMenuStrip) {
            $script:notifyIcon.ContextMenuStrip.Dispose()
        }
        $script:notifyIcon.Dispose()
        $script:notifyIcon = $null
    }
}