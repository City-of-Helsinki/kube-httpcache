ARG DEBIAN_ARCH=amd64
FROM        ${DEBIAN_ARCH}/debian:bookworm-slim

LABEL       MAINTAINER="Martin Helmich <m.helmich@mittwald.de>"

WORKDIR     /

# varnish
RUN         apt-get -qq update && apt-get -qq upgrade -y && \
            apt-get -qq install -y curl gnupg ca-certificates && \
            install -m 0755 -d /etc/apt/keyrings && \
            curl -fsSL https://packagecloud.io/varnishcache/varnish76/gpgkey | gpg --dearmor -o /etc/apt/keyrings/varnishcache-archive-keyring.gpg && \
            echo "deb [signed-by=/etc/apt/keyrings/varnishcache-archive-keyring.gpg] https://packagecloud.io/varnishcache/varnish76/debian/ bookworm main" > /etc/apt/sources.list.d/varnishcache_varnish76.list && \
            apt-get -qq update && apt-get -qq install -y varnish && \
            apt-get -qq purge -y curl gnupg && \
            apt-get -qq autoremove -y && apt-get -qq autoclean && \
            rm -rf /var/cache/* && rm -rf /var/lib/apt/lists/*

RUN         mkdir /exporter && \
            chown varnish /exporter

# exporter
ARG ARCH=amd64
ENV         ARCH="${ARCH}"
ENV         EXPORTER_VERSION="v1.7.0"
ADD         --chown=varnish https://github.com/leontappe/prometheus_varnish_exporter/releases/download/${EXPORTER_VERSION}/prometheus_varnish_exporter-${EXPORTER_VERSION}.linux-${ARCH}.tar.gz /tmp

RUN         cd /exporter && \
            tar -xzf /tmp/prometheus_varnish_exporter-${EXPORTER_VERSION}.linux-${ARCH}.tar.gz && \
            ln -sf /exporter/prometheus_varnish_exporter-${EXPORTER_VERSION}.linux-${ARCH}/prometheus_varnish_exporter prometheus_varnish_exporter

COPY        kube-httpcache .

ENTRYPOINT [ "/kube-httpcache" ]