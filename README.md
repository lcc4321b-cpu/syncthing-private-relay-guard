# Syncthing Private Relay Guard

一套面向“私有 Syncthing relay/discovery + Windows 客户端”的轻量自愈工具。它解决的不是 Syncthing 文件协议本身，而是长期运行中常见的控制面漂移：防火墙规则被 reload 清掉、relay/discovery 服务退出、Windows 计划任务到期、winget 升级后可执行文件路径变化。

## 解决什么问题

- Linux 服务器每 5 分钟验证私有 relay/discovery 服务、监听端口和 firewalld 规则。
- 端口规则或服务异常时自动恢复，并把动作写入 system journal。
- Windows 登录后静默启动 Syncthing，并在退出后自动重试。
- Windows 启动器动态查找 winget 当前安装的最新 Syncthing，避免硬编码版本路径。
- 保持 relay/discovery 服务器只承担连接协调，不存储同步文件。

## 项目结构

```text
linux/
  install.sh
  syncthing-control-plane-health
  syncthing-control-plane-health.service
  syncthing-control-plane-health.timer
windows/
  install-task.ps1
  start-syncthing.ps1
docs/
  verification.md
```

## Linux 服务器安装

前提：`strelaysrv.service`、`stdiscosrv.service` 和 firewalld 已存在。默认端口为 relay `22067/tcp`、discovery `8443/tcp`。

```bash
sudo ./linux/install.sh
```

可通过环境变量覆盖服务名和端口：

```bash
sudo RELAY_PORT=22067 DISCOVERY_PORT=8443 \
  RELAY_SERVICE=strelaysrv DISCOVERY_SERVICE=stdiscosrv \
  ./linux/install.sh
```

安装后会启用 `syncthing-control-plane-health.timer`。健康检查的运行记录可用以下命令查看：

```bash
systemctl status syncthing-control-plane-health.timer
journalctl -u syncthing-control-plane-health.service
```

## Windows 客户端安装

前提：Syncthing 由 winget 安装，并且当前用户已有可用的 Syncthing 配置。

在普通 PowerShell 中运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\windows\install-task.ps1
```

它会创建 `Syncthing Private Relay Background` 计划任务：登录触发、每 5 分钟幂等触发、运行中忽略重复实例、无限执行时长、失败后每分钟重试。

## 安全边界

- 本仓库不包含 relay token、Syncthing API key、设备 ID、服务器地址或真实同步目录。
- 不要把 Syncthing 的配置目录、证书、密钥或事故日志提交到仓库。
- relay/discovery 服务器不缓存业务文件。若两台终端不能同时在线，文件不会在离线期间暂存到服务器。
- 公开仓库前请执行文档中的敏感信息扫描。

完整验收步骤见 [docs/verification.md](docs/verification.md)。

