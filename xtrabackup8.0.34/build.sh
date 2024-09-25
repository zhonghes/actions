#!/usr/bin/env bash

# 开启调试模式
set -x

function CheckPackageVersion() {
    [[ $# -eq 2 ]] || { echo "${FUNCNAME[0]} 函数传入参数【$*】有误"; return 1; }

    local _pkg_version _min_version
    _pkg_version="${1}"
    _min_version="${2}"

    if [[ ${_pkg_version%.*} -le ${_min_version%.*} ]]; then
        [[ ${_pkg_version%.*} -eq ${_min_version%.*} && ${pkg_version#*.} -ge ${_min_version#*.} ]] || return 1
    fi

    return 0
}

function Main() {
    # 安装编译依赖
    yum install -y cmake openssl-devel libaio libaio-devel automake autoconf bison libtool ncurses-devel libgcrypt-devel libev-devel libcurl-devel zlib-devel libgudev-devel zstd vim-common procps-ng-devel rpm-build readline-devel make gcc gcc-c++ wget tree || return 1

    # 复用 centos8 依赖包
    yum install -y "https://dl.fedoraproject.org/pub/epel/8/Everything/$(uname -m)/Packages/p/patchelf-0.12-1.el8.$(uname -m).rpm"

    # 确认 gcc 版本
    pkg_version=$(gcc --version | grep -oP '(?<=\s)\d+\.\d+') || { echo "获取 gcc 版本号失败"; return 1; }
    min_version=7.5
    CheckPackageVersion "${pkg_version}" "${min_version}" || { echo "gcc 版本低于 ${min_version}"; return 1; }

    # 确认空余磁盘大于 30G
    if ! df --block-size=G / | awk '{if(($4+0)>30) print $NF}' | grep -q .; then
        df -h
        # build_paht=$(df --block-size=G | awk '{if(($4+0)>30) print $NF}' | grep -Pv 'docker|^[^/]' | head -n 1)
        # { [[ -z ${build_paht} ]] && "echo 磁盘不足 30G" && return 1; } || ln -s /root/build "${build_paht}"
    fi

    # 下载 src.rpm
    wget -c https://downloads.percona.com/downloads/Percona-XtraBackup-8.0/Percona-XtraBackup-8.0.34-29/source/redhat/percona-xtrabackup-80-8.0.34-29.1.generic.src.rpm

    # 通过 src.rpm 重新编译
    rpmbuild --nodebuginfo --rebuild percona-xtrabackup-80-8.0.34-29.1.generic.src.rpm || { echo "编译失败"; return 1; }

    # 将编译文件拷贝至指定目录
    dest_path="/github/workspace/$1"
    os_pretty_name="$(grep -oP '(?<=PRETTY_NAME=").+?(?=")' /etc/os-release | sed 's| |_|g')" || return 1
    dest_build_path="${dest_path}/${os_pretty_name}/$(uname -m)" || return 1
    rm -fr "${dest_build_path}"
    mkdir -p "${dest_build_path}"
    cp -a ~/rpmbuild/{SRPMS,RPMS} "${dest_build_path}"

    # 显示当前仓库目录结构
    tree /github/workspace || return 1
}

Main "$@"


