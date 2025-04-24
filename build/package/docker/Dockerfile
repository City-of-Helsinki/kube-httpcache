###############
# Stage 1: Build kube-httpcache
###############
ARG GO_VERSION=1.23.6-1.1744600118
FROM registry.redhat.io/rhel8/go-toolset:${GO_VERSION} AS builder
USER 0
WORKDIR /workspace
COPY . .
RUN chmod -R g+w /workspace && \
    CGO_ENABLED=0 GOOS=linux \
    go build -o kube-httpcache ./cmd/kube-httpcache

###############
# Stage 2: Build Prometheus Varnish Exporter
###############
FROM registry.redhat.io/rhel8/go-toolset:${GO_VERSION} AS builder-exporter
USER 0
ARG EXPORTER_VERSION=1.6.1
WORKDIR /workspace
RUN yum update -y && \
    yum install -y git && \
    git clone https://github.com/jonnenauha/prometheus_varnish_exporter.git --branch ${EXPORTER_VERSION} --depth 1 && \
    cd prometheus_varnish_exporter && \
    chmod -R g+w /workspace && \
    go build -o /workspace/prometheus_varnish_exporter && \
    yum remove -y git && \
    yum clean all && \
    rm -rf /var/cache/yum /tmp/* /var/tmp/*

###############
# Stage 3: Final Image with Varnish 7.7 on UBI 9
###############
FROM registry.redhat.io/ubi9/ubi:9.5-1744101466 AS final
USER 0

ARG VARNISH_REPO_VERSION=77
ARG VARNISH_VERSION=7.7.0
ARG VARNISH_RELEASE=1
ARG VARNISH_ARCH=el9.x86_64

# Install jemalloc from EPEL and Varnish from packagecloud
RUN yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm && \
    yum install -y jemalloc && \
    curl -s https://packagecloud.io/install/repositories/varnishcache/varnish${VARNISH_REPO_VERSION}/script.rpm.sh | bash && \
    yum install -y varnish-${VARNISH_VERSION}-${VARNISH_RELEASE}.${VARNISH_ARCH} && \
    yum clean all && \
    rm -rf /var/cache/yum /tmp/* /var/tmp/* && \
    mkdir -p /exporter && chown -R 1001:0 /exporter

COPY --from=builder --chown=1001:0 /workspace/kube-httpcache .
COPY --from=builder-exporter --chown=1001:0 /workspace/prometheus_varnish_exporter /exporter/

USER 1001
ENTRYPOINT ["/kube-httpcache"]