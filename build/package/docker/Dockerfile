###############
# Stage 1: Build kube-httpcache
###############
ARG GO_VERSION=1.23.6-1.1744600118
FROM registry.access.redhat.com/ubi9/go-toolset:${GO_VERSION} as builder
WORKDIR /workspace
COPY . .
RUN CGO_ENABLED=0 GOOS=linux \
    go build -installsuffix cgo -o kube-httpcache -a cmd/kube-httpcache/main.go
###############
# Stage 2: Build Prometheus Varnish Exporter
###############
ARG GO_VERSION=1.23.6-1.1744600118
FROM registry.access.redhat.com/ubi9/go-toolset:${GO_VERSION} AS builder-exporter
ARG EXPORTER_VERSION=1.6.1
WORKDIR /workspace
RUN yum update -y && \
    yum install -y git ca-certificates && \
    git clone https://github.com/jonnenauha/prometheus_varnish_exporter.git --branch ${EXPORTER_VERSION} --depth 1 && \
    cd prometheus_varnish_exporter && \
    go build -o /workspace/prometheus_varnish_exporter && \
    yum remove -y git && \
    yum clean all && \
    rm -rf /var/cache/yum /tmp/* /var/tmp/*
###############
# Stage 3: Final Image with Varnish 7.7 on UBI 9
###############
FROM registry.redhat.io/ubi9/ubi:9.5-1744101466 AS final
ARG VARNISH_REPO_VERSION=77
ARG VARNISH_VERSION=7.7.0
ARG VARNISH_RELEASE=1
ARG VARNISH_ARCH=el9.x86_64
WORKDIR /
RUN yum install -y curl ca-certificates && \
    curl -s https://packagecloud.io/install/repositories/varnishcache/varnish${VARNISH_REPO_VERSION}/script.rpm.sh | bash && \
    yum install -y varnish-${VARNISH_VERSION}-${VARNISH_RELEASE}.${VARNISH_ARCH} && \
    yum clean all && \
    rm -rf /var/cache/yum /tmp/* /var/tmp/*

RUN mkdir -p /exporter && chown -R varnish /exporter
COPY --from=builder /workspace/kube-httpcache .
COPY --from=builder-exporter /workspace/prometheus_varnish_exporter /exporter/

ENTRYPOINT ["/kube-httpcache"]
