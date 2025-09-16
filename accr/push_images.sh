#!/usr/bin/env bash

# 格式一：
#     平台,镜像,前缀
# 格式二：
#   镜像
LIST_IMAGES=(
    "redis:6"
    "linux/arm64/v8,redis:6,aarch64"
    "redis:7"
    "outlinewiki/outline:latest"
)

function Main() {
    local _platform _prefix _tag _new_tag
    
    for image in "${LIST_IMAGES[@]}"; do
        if echo "${image}" | awk -F ',' '{print NF}' | grep -q -s '3'; then
            _platform=$(echo "${image}" | awk -F ',' '{print $1}')
            _tag=$(echo "${image}" | awk -F ',' '{print $2}')
            _prefix=$(echo "${image}" | awk -F ',' '{print $3}')

            _new_tag="crpi-qqjr4xowoqr9zwh0.cn-beijing.personal.cr.aliyuncs.com/zhonghes/${_prefix}_${_tag##*/}"
        else
            _new_tag="crpi-qqjr4xowoqr9zwh0.cn-beijing.personal.cr.aliyuncs.com/zhonghes/${_tag##*/}"
        fi
        
        docker pull "${_tag}"
        docker tag "${_tag}" "${_new_tag}"
        docker push "${_new_tag}"
    done
}

Main "$@"
