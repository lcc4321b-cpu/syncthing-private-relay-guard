$ErrorActionPreference = 'Stop'

$packageRoot = Join-Path $env:LOCALAPPDATA `
    'Microsoft\WinGet\Packages\Syncthing.Syncthing_Microsoft.Winget.Source_8wekyb3d8bbwe'

$syncthingExe = Get-ChildItem -LiteralPath $packageRoot `
    -Filter syncthing.exe -Recurse -File -ErrorAction Stop |
    Sort-Object { [version]$_.VersionInfo.FileVersion } -Descending |
    Select-Object -First 1

if (-not $syncthingExe) {
    throw "Syncthing executable was not found under $packageRoot"
}

& $syncthingExe.FullName serve --no-console --no-browser --no-restart --no-upgrade
exit $LASTEXITCODE

