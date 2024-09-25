# 使用说明

更新本文档，触发 `.github/actions/build_openssh.yml` 工作流，自动编译相关操作系统的 openssh 软件包，并上传至本目录

# 升级 openssh 须知

> [!WARNING]
> * 欧拉（openEuler）系统不建议直接升级，建议优先前往官方安全中心使用官方补丁修复：https://www.openeuler.org/zh/security/security-bulletins<br>
> * 银河麒麟（kylin）系统不建议直接升级，建议优先前往官方安全中心使用官方补丁修复：https://kylinos.cn/support/loophole/patch.html<br>
> * 统信（uos）系统不建议直接升级，建议优先前往官方安全中心使用官方补丁修复：https://src.uniontech.com/#/security_advisory

当前最新版本：
* openssh-9.8p1
* OpenSSL 3.0.14 / 3.0.9

> [!CAUTION]
> * 升级前请务必确保可以使用 telnet 或 ttyd 等工具登录 root 用户，以防升级异常后无法远程服务器
> * 升级后 openssh 配置文件会被覆盖，如有特殊配置（比如禁止密码登录等），请务必重新配置，其余配置事项见链接：https://github.com/boypt/openssh-rpms?tab=readme-ov-file#security-notes

升级详情见链接：https://github.com/boypt/openssh-rpms?tab=readme-ov-file#install-rpms
