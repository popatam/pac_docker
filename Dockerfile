FROM golang:1.22-alpine as xray-knife-build
RUN apk add --no-cache \
      git
RUN git clone https://github.com/lilendian0x00/xray-knife.git && cd xray-knife && go build . #&& ln -s /xray-knife/xray-knife /usr/local/bin/xray-knife

FROM ghcr.io/shadowsocks/sslocal-rust:latest as pac

RUN apk add --no-cache \
    netcat-openbsd \
    bash

COPY --from=xray-knife-build /go/xray-knife/xray-knife /usr/bin/
COPY run.sh /run.sh
COPY localproxy.pac.orig /localproxy.pac.orig

EXPOSE 1080 8999

ENTRYPOINT ["bash", "/run.sh"]