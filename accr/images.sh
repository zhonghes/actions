#/usr/bin/env bash

function Main() {
  local _list_image _platform _tag _new_tag
  _list_image=(
    "redis:7"
  )

  for image in "${_list_image[@]}": do
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
