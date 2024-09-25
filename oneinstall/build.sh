#!/usr/bin/env bash

set -x

function EchoColor() {
    [ $# -eq 2 ] || { Prompt "${FUNCNAME[0]} 函数传入参数错误"; return 1; }
    echo -e "\e[0;${1}m${2}\e[0m"
}

function Info() {
    EchoColor 32 "[$(date '+%FT%T.%N %z')] $*"
}

function Warn() {
    EchoColor 33 "[$(date '+%FT%T.%N %z')] $*"
}

function Err() {
    EchoColor 31 "[$(date '+%FT%T.%N %z')] $*" >&2
}

# shellcheck disable=SC2120
function CreateCentos8Repo {
    [[ $# -le 1 ]] || { Err "${FUNCNAME[0]} 函数传入参数【$*】有误"; return 1; }

    local _repo_path
    [[ $# -eq 1 ]] &&  _repo_path="${1}"
    _repo_path="${_repo_path:-/etc/yum.repos.d}"

    mkdir -p "${_repo_path}"

    # opel
    cat > "${_repo_path}/epel.repo" << EOF
[epel]
name=Extra Packages for Enterprise Linux 8 - $(uname -m)
baseurl=https://mirrors.huaweicloud.com/epel/8/Everything/$(uname -m)
enabled=1
gpgcheck=0
priority=999
EOF

    # openresty
    cat > "${_repo_path}/openresty.repo" << EOF
[openresty]
name=Official OpenResty Open Source Repository for CentOS
baseurl=https://openresty.org/package/centos/8/$(uname -m)/
skip_if_unavailable=False
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://openresty.org/package/pubkey.gpg
enabled=1
enabled_metadata=1
priority=-1
EOF

    #  mysql-community-server
    cat > "${_repo_path}/mysql-community.repo" << EOF
[mysql80-community]
name=MySQL 8.0 Community Server
baseurl=http://repo.mysql.com/yum/mysql-8.0-community/el/8/$(uname -m)/
enabled=1
gpgcheck=0
priority=-1

[mysql-connectors-community]
name=MySQL Connectors Community
baseurl=http://repo.mysql.com/yum/mysql-connectors-community/el/8/$(uname -m)/
enabled=1
gpgcheck=0
priority=-1

[mysql-tools-community]
name=MySQL Tools Community
baseurl=http://repo.mysql.com/yum/mysql-tools-community/el/8/$(uname -m)/
enabled=1
gpgcheck=0
priority=-1
EOF

yum clean all && yum makecache
}

# 获取指定配置文件中的指定部分内容
function GetSection() {
    [[ $# -le 2 ]] || { Err "${FUNCNAME[0]} 函数传入参数【$*】有误"; return 1; }
    unset RETURN

    local _section _config_file
    _section="${1}"
    [[ $# -eq 2 ]] && _config_file="${2}" || _config_file="config.ini"

    if [[ ${_section} == "all" ]]; then
        while IFS='' read -r; do RETURN+=("${REPLY}"); done < <(grep -vP "^\s*(#|;|\[|$)" "${_config_file}")
    else
        while IFS='' read -r; do RETURN+=("${REPLY}"); done < <(sed -nr "/^\s*\[${_section}\]/,/\s*\[/{/^\s*(#|;|\[|$)/d; p;}" "${_config_file}")
    fi

    return 0
}

function CreateUnusualRepo {
    [[ $# -eq 2 ]] || { Err "${FUNCNAME[0]} 函数传入参数【$*】有误"; return 1; }
    unset RETURN

    local _download_dir _ini_file _array_element _file_path _array_return
    _download_dir="${1}"
    _ini_file="${2}"

    [[ -d ${_download_dir} ]] || { Err "错误：${_download_dir} 目录不存在"; return 1; }
    [[ -f ${_ini_file} ]] || { Err "错误：${_ini_file} 文件不存在"; return 1; }

    if GetSection unusual "${_ini_file}" && [[ -n ${RETURN[*]} ]]; then
        _array_element=("${RETURN[@]}")

        # ntpdate
        _file_path="rpms/$(uname -m)/ntpdate-4.2.8p15-1.mga8.$(uname -m).rpm"
        \cp "${_file_path}" "${_download_dir}" || _array_return+=("ntpdate")

        # jdk
        # 即：oraclejdk
        [[ $(uname -m) == "x86_64" ]] && _file_path="rpms/$(uname -m)/jdk-8u421-linux-x64.rpm" \
            || _file_path="rpms/$(uname -m)/jdk-8u421-linux-$(uname -m).rpm"
        \cp "${_file_path}" "${_download_dir}" || _array_return+=("ntpdate")

        # redis
        # 自行编译，手动处理
        _file_path="srpms/$(uname -m)/redis-6.0.20-1.src.rpm"
        dnf install -y git rpmdevtools make pkgconfig systemd-devel openssl-devel gcc gcc-c++
        rpmbuild --rebuild --nodebuginfo "${_file_path}" || _array_return+=("ntpdate")
        \cp ~/rpmbuild/RPMS/*/redis-*.rpm "${_download_dir}"

        # cetus
        # 自行编译，手动处理
        _file_path="srpms/$(uname -m)/cetus-2-4.0.src.rpm"
        dnf install -y libevent-devel openssl-devel tar cmake flex gcc glib2-devel mysql-community-devel gperftools-libs zlib-devel rpm-build rpmdevtools
        rpmbuild --rebuild --nodebuginfo "${_file_path}" || _array_return+=("ntpdate")
        \cp ~/rpmbuild/RPMS/*/cetus-*.rpm "${_download_dir}"

        # percona-xtrabackup-80
        # 自行编译，手动处理
        _file_path="srpms/$(uname -m)/percona-xtrabackup-80-8.0.34-29.1.src.rpm"
        yum install -y wget cmake openssl-devel libaio libaio-devel automake autoconf bison libtool ncurses-devel libgcrypt-devel libev-devel libcurl-devel zlib-devel zstd vim-common  patchelf rpm-build readline-devel make rpmdevtools /usr/lib64/libgudev-1.0.so.0 gcc g++
        yum install -y /usr/lib64/libprocps.so || yum install -y https://dl.rockylinux.org/pub/rocky/8/Devel/"$(uname -m)"/os/Packages/p/{procps-ng,procps-ng-devel}-3.3.15-14.el8."$(uname -m)".rpm
        rpmbuild --rebuild --nodebuginfo "${_file_path}" || _array_return+=("ntpdate")
        \cp ~/rpmbuild/RPMS/*/percona-xtrabackup-80-*.rpm "${_download_dir}"

        # mydumper
        # 直接官方仓库下载 el8 的包即可
        _file_path="rpms/$(uname -m)/mydumper-0.16.7-5.el8.$(uname -m).rpm"
        \cp "${_file_path}" "${_download_dir}" || _array_return+=("ntpdate")

        # tdengine
        # 走二进制，不做处理，将单独提供

        # postgis
        # 走 docker 镜像，不做处理

        [[ -n ${_array_return[*]} ]] && { RETURN=("${_array_return[@]}"); return 1; }    

        # 创建本地仓库
        createrepo "${_download_dir}" && ( repo2module "$_" && createrepo_mod "$_" ) 2>/dev/null
        cat > /etc/yum.repos.d/local.repo << EOF
[local]
name=unusualrepo
baseurl="file://${_download_dir}"
enabled=1
gpgcheck=0
priority=-1
EOF
        yum clean all && yum makecache

    fi

    return 0
}

# 下载依赖包
function RepotrackPackage() {
    [[ $# -eq 2 ]] || { Err "${FUNCNAME[0]} 函数传入参数【$*】有误"; return 1; }
    unset RETURN

    local _download_dir _ini_file _array_element _array_check_fail _array_return
    _download_dir="${1}"
    _ini_file="${2}"

    [[ -d ${_download_dir} ]] || { Err "错误：${_download_dir} 目录不存在"; return 1; }
    [[ -f ${_ini_file} ]] || { Err "错误：${_ini_file} 文件不存在"; return 1; }

    if GetSection all "${_ini_file}" && [[ -n ${RETURN[*]} ]]; then
        _array_element=("${RETURN[@]}")
        _array_check_fail=()

        while IFS='' read -r; do _array_check_fail+=("${REPLY}"); done < <(dnf install "${_array_element[@]}" --assumeno 2>/dev/null | grep -P 'No match for argument|未找到匹配的参数' | grep -oP '[^\s:：]+$')
        if [[ -z ${_array_check_fail[*]} ]]; then
            # dnf install -y --downloadonly --downloaddir "${_download_dir}" "${_array_element[@]}" || _array_return+=("${_array_element[@]}")
            repotrack --downloaddir "${_download_dir}" "${_array_element[@]}" || _array_return+=("${_array_element[@]}")
        else
            _array_return+=("${_array_check_fail[@]}")
        fi

    fi

    [[ -n ${_array_return[*]} ]] && { RETURN=("${_array_return[@]}"); return 1; }    
    return 0
}

function Main() {
    # 检测相关依赖，未安装则直接安装
    env dnf --version >/dev/null || { Err "未找到 dnf 命令"; return 1; }
    env wget --version >/dev/null || { dnf install -y wget || return 1; }
    if ! env createrepo --version >/dev/null; then
        dnf install -y /usr/bin/createrepo || return 1
        dnf install -y /usr/bin/createrepo_mod
    fi
    if ! env repotrack --version >/dev/null; then
        dnf install -y /usr/bin/repotrack || return 1
    fi

    # 创建 Centos8 相关 yum 仓库
    CreateCentos8Repo || return 1
    yum module disable mysql redis openrestry -y

    # mkdir -p /egova/unusualrepo
    # if CreateUnusualRepo /egova/unusualrepo package.ini; then
    #     Info "特殊处理软件仓库创建成功"
    # else
    #     Err "错误：${RETURN[*]} 特殊处理包仓库创建失败"
    #     return 1
    # fi

    mkdir -p /egova/repotrack
    if RepotrackPackage /egova/repotrack package.ini; then
        Info "依赖包拉取完成"
    else
        Err "错误：${RETURN[*]} 软件包拉取依赖包失败"
        return 1
    fi

    cp -a /egova/repotrack /github/workspace/oneinstall
}

Main "$@"
