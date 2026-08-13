using System;
using System.Diagnostics;
using System.IO;

class Program
{
    static void Main(string[] args)
    {
        string log = @"C:\WorkTimer\logs\protocol-debug.log";

        try
        {
            File.AppendAllText(log, $"{DateTime.Now:o} started\n");

            if (args.Length == 0)
            {
                File.AppendAllText(log, "No arguments\n");
                return;
            }

            string uri = args[0];
            File.AppendAllText(log, $"URI: {uri}\n");
            
            string executionDir = AppDomain.CurrentDomain.BaseDirectory;        
            DirectoryInfo executionDirectory = new DirectoryInfo(executionDir);
            string parentDir = executionDirectory.Parent!.FullName;

            string pwsh = @"C:\Program Files\PowerShell\7\pwsh.exe";
            string script = Path.Combine(
                parentDir,
                "scripts",
                "toast_handler.ps1"
            );

            File.AppendAllText(log, $"executionDir: {executionDir}\n");
            File.AppendAllText(log, $"parentDir: {parentDir}\n");
            File.AppendAllText(log, $"script: {script}\n");
            File.AppendAllText(log, $"script exists: {File.Exists(script)}\n");

            var psi = new ProcessStartInfo
            {
                FileName = pwsh,
                UseShellExecute = false,
                CreateNoWindow = true
            };

            psi.ArgumentList.Add("-NoProfile");
            psi.ArgumentList.Add("-ExecutionPolicy");
            psi.ArgumentList.Add("Bypass");
            psi.ArgumentList.Add("-File");
            psi.ArgumentList.Add(script);
            psi.ArgumentList.Add(uri);

            Process.Start(psi);

            File.AppendAllText(log, "PowerShell started\n");
        }
        catch (Exception ex)
        {
            File.AppendAllText(log, $"ERROR: {ex}\n");
        }
    }
}