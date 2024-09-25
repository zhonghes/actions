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
    dnf install -y git rpmdevtools make pkgconfig systemd-devel openssl-devel gcc gcc-c++ wget findutils libatomic tree || exit 1

    # 确认 gcc 版本
    pkg_version=$(gcc --version | grep -oP '(?<=\s)\d+\.\d+') || { echo "获取 gcc 版本号失败"; exit 1; }
    min_version=5.3
    CheckPackageVersion "${pkg_version}" "${min_version}" || { echo "gcc 版本低于 ${min_version}"; exit 1; }

    # 克隆仓库，切换分支
    git clone https://src.fedoraproject.org/rpms/redis.git || exit 1
    cd redis || exit 1
    git checkout 1b9dab8fcdec8597e1b2edf24f491f4bb3d14dac || exit 1

    # 生成打包路径
    rpmdev-setuptree || exit 1

    # 处理 spec 文件，兼容指定版本
    cp -a ./* ~/rpmbuild/SOURCES/
    sed -i 's/Version:           6.0.11/Version:           6.0.20/'  ~/rpmbuild/SOURCES/redis.spec  || exit 1

    # 下载源码文件
    cd ~/rpmbuild/SOURCES || exit 1
    rpmspec -P redis.spec | grep -oP '(?<=[\s])http.+tar.gz' | xargs -i wget -c {} || exit 1

    # 打包
    rpmbuild -ba ~/rpmbuild/SOURCES/redis.spec || exit 1

    # 将编译文件拷贝只指定目录
    dest_path="/github/workspace/$1"
    os_pretty_name="$(grep -oP '(?<=PRETTY_NAME=").+?(?=")' /etc/os-release | sed 's| |_|g')" || exit 1
    dest_build_path="${dest_path}/${os_pretty_name}/$(uname -m)" || exit 1
    rm -fr "${dest_build_path}"
    mkdir -p "${dest_build_path}"
    cp -a ~/rpmbuild/{SRPMS,RPMS} "${dest_build_path}"

    # 显示当前仓库目录结构
    tree /github/workspace || exit 1
}

Main "$@"