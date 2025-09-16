#/usr/bin/env bash

LIST_IMAGES=(
    "redis:7"
  )

function Main() {
  local _tag _new_tag

  for image in "${LIST_IMAGES[@]}": do
    # _platform="${image%,*}"
    _tag="${image#*,}"
    _new_tag="crpi-qqjr4xowoqr9zwh0.cn-beijing.personal.cr.aliyuncs.com/zhonghes/${_tag}"
    # docker pull --platform="${_platform}" "${_tag}"
    docker pull "${_tag}"
    docker tag "${_tag}" "${_new_tag}"
    docker push "${_new_tag}"
  done
}

Main "$@"
