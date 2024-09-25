FROM --platform=$TARGETPLATFORM openeuler/openeuler:22.03-lts as build

ENV TZ=Asia/Shanghai

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["sh", "/entrypoint.sh"]
