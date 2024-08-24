FROM ghcr.io/shadowsocks/sslocal-rust:latest

RUN apk add --no-cache \
    netcat-openbsd \
    bash \
    git

COPY --from=golang:1.21-alpine /usr/local/go/ /usr/local/go/

ENV PATH="/usr/local/go/bin:${PATH}"

RUN git clone https://github.com/lilendian0x00/xray-knife.git && cd xray-knife && go build . && ln -s /xray-knife/xray-knife /usr/local/bin/xray-knife

COPY run.sh /run.sh
COPY localproxy.pac.orig /localproxy.pac.orig

EXPOSE 1080 8999

ENTRYPOINT ["bash", "/run.sh"]