# Verification

## Static checks

```bash
bash -n linux/install.sh
bash -n linux/syncthing-control-plane-health
systemd-analyze verify \
  linux/syncthing-control-plane-health.service \
  linux/syncthing-control-plane-health.timer
```

```powershell
$errors = $null
[System.Management.Automation.Language.Parser]::ParseFile(
    "$PWD\windows\start-syncthing.ps1", [ref]$null, [ref]$errors
) | Out-Null
$errors
```

## Linux runtime checks

```bash
systemctl is-active firewalld strelaysrv stdiscosrv
systemctl is-enabled firewalld strelaysrv stdiscosrv
systemctl is-active syncthing-control-plane-health.timer
firewall-cmd --query-port=22067/tcp
firewall-cmd --query-port=8443/tcp
ss -lnt | grep -E ':(22067|8443)\b'
```

## Self-healing test

Only run these tests during a maintenance window because they briefly alter runtime state.

```bash
sudo firewall-cmd --remove-port=22067/tcp
sudo systemctl start syncthing-control-plane-health.service
sudo firewall-cmd --query-port=22067/tcp

sudo systemctl stop stdiscosrv
sudo systemctl start syncthing-control-plane-health.service
systemctl is-active stdiscosrv
```

## Windows runtime checks

```powershell
Get-ScheduledTask -TaskName 'Syncthing Private Relay Background'
Get-NetTCPConnection -State Listen -LocalPort 8384
Get-Process syncthing
```

## Pre-publication secret scan

Review every match before making the repository public:

```bash
git grep -nEi 'token=|api[_-]?key|password|secret|device.?id|([0-9]{1,3}\.){3}[0-9]{1,3}'
```

