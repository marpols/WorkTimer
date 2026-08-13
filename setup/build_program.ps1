dotnet publish .\WorkTimerProtocol.csproj `
>>     -c Release `
>>     -r win-x64 `
>>     --self-contained false `
>>     -o "$(Split-Path -Path $PSScriptRoot)\protocol"