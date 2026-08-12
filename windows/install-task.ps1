$ErrorActionPreference = 'Stop'

$taskName = 'Syncthing Private Relay Background'
$installDir = Join-Path $env:LOCALAPPDATA 'Syncthing\guard'
$sourceLauncher = Join-Path $PSScriptRoot 'start-syncthing.ps1'
$installedLauncher = Join-Path $installDir 'start-syncthing.ps1'

New-Item -ItemType Directory -Path $installDir -Force | Out-Null
Copy-Item -LiteralPath $sourceLauncher -Destination $installedLauncher -Force

$action = New-ScheduledTaskAction `
    -Execute 'powershell.exe' `
    -Argument ('-NoLogo -NoProfile -NonInteractive -WindowStyle Hidden ' +
        '-ExecutionPolicy Bypass -File "' + $installedLauncher + '"')
$logonTrigger = New-ScheduledTaskTrigger `
    -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"
$watchdogTrigger = New-ScheduledTaskTrigger `
    -Once -At (Get-Date).AddMinutes(1) `
    -RepetitionInterval (New-TimeSpan -Minutes 5)
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -MultipleInstances IgnoreNew `
    -RestartCount 999 `
    -RestartInterval (New-TimeSpan -Minutes 1) `
    -ExecutionTimeLimit ([TimeSpan]::Zero)
$principal = New-ScheduledTaskPrincipal `
    -UserId "$env:USERDOMAIN\$env:USERNAME" `
    -LogonType Interactive `
    -RunLevel Limited

Register-ScheduledTask `
    -TaskName $taskName `
    -Action $action `
    -Trigger @($logonTrigger, $watchdogTrigger) `
    -Settings $settings `
    -Principal $principal `
    -Description 'Keep Syncthing running silently for private relay synchronization.' `
    -Force | Out-Null

Start-ScheduledTask -TaskName $taskName
Get-ScheduledTask -TaskName $taskName

