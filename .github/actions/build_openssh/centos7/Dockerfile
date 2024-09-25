FROM --platform=$TARGETPLATFORM centos:7 as build

ENV TZ=Asia/Shanghai

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["sh", "/entrypoint.sh"]
