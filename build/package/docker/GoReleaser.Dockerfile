ARG DEBIAN_ARCH=amd64
FROM        ${DEBIAN_ARCH}/debian:bookworm-slim

LABEL       MAINTAINER="Martin Helmich <m.helmich@mittwald.de>"

WORKDIR     /

# varnish
RUN         apt-get -qq update && apt-get -qq upgrade && apt-get -qq install curl && \
            curl -s https://packagecloud.io/install/repositories/varnishcache/varnish76/script.deb.sh | bash && \
            apt-get -qq update && apt-get -qq install varnish && \
            apt-get -qq purge curl gnupg && \
            apt-get -qq autoremove && apt-get -qq autoclean && \
            rm -rf /var/cache/* && rm -rf /var/lib/apt/lists/*

RUN         mkdir /exporter && \
            chown varnish /exporter

# exporter
FROM alpine:latest

# Create non-root user first
RUN addgroup -S varnish && adduser -S varnish -G varnish

ARG ARCH=amd64
ENV ARCH="${ARCH}"
ENV EXPORTER_VERSION="v1.7.0"

# Get the SHA256 checksum for verification (replace with actual checksum)
ARG EXPORTER_CHECKSUM="REPLACE_WITH_ACTUAL_SHA256_CHECKSUM"

# Download with verification instead of ADD
RUN wget -O /tmp/exporter.tar.gz \
    https://github.com/leontappe/prometheus_varnish_exporter/releases/download/${EXPORTER_VERSION}/prometheus_varnish_exporter-${EXPORTER_VERSION}.linux-${ARCH}.tar.gz && \
    echo "${EXPORTER_CHECKSUM}  /tmp/exporter.tar.gz" | sha256sum -c - && \
    mkdir -p /exporter && \
    cd /exporter && \
    tar -xzf /tmp/exporter.tar.gz && \
    rm -f /tmp/exporter.tar.gz && \
    chown -R varnish:varnish /exporter && \
    find /exporter -type f -exec chmod 644 {} \; && \
    find /exporter -type d -exec chmod 755 {} \; && \
    chmod 755 /exporter/prometheus_varnish_exporter-${EXPORTER_VERSION}.linux-${ARCH}/prometheus_varnish_exporter

# Create symbolic link
RUN ln -sf /exporter/prometheus_varnish_exporter-${EXPORTER_VERSION}.linux-${ARCH}/prometheus_varnish_exporter /exporter/prometheus_varnish_exporter

# Copy application with proper permissions
COPY --chown=varnish:varnish kube-httpcache /

# Switch to non-root user
USER varnish

ENTRYPOINT [ "/kube-httpcache" ]