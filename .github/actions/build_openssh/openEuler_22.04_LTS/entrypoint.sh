#!/usr/bin/env bash

# 获取指定存储路径
dest_path="/github/workspace/$1"

# 安装编译环境
yum groupinstall -y "Development Tools"
yum install -y imake rpm-build pam-devel krb5-devel zlib-devel libXt-devel libX11-devel gtk2-devel perl perl-IPC-Cmd tree

# 拉取 openssh-rpms 仓库
cd "$(mktemp -d)" || exit 1
curl -fsSL -o main.zip https://github.com/boypt/openssh-rpms/archive/refs/heads/main.zip
unzip main.zip || exit 1
cd openssh-rpms-main || exit 1

# 编译 openssh
./pullsrc.sh && ./compile.sh || exit 1

# 查看编译文件
cd "$(./compile.sh RPMDIR)" || exit 1

# 拷贝编译文件至指定目录
# shellcheck disable=SC2010
openssh_path="${dest_path}/$(ls | grep -oP '^openssh-\d.+(?=\.rpm$)')"
mkdir -p "${openssh_path}"
cp -a ./*.rpm "${openssh_path}"

# 显示当前仓库目录结构
tree /github/workspace
