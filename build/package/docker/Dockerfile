###############
# Stage 1: Build kube-httpcache (Multi-stage)
###############
ARG GO_VERSION=$__GO_VERSION__
FROM registry.redhat.io/rhel8/go-toolset:$__GO_VERSION__ AS builder
USER 0
WORKDIR /workspace
COPY go.mod go.sum ./
COPY ./cmd/kube-httpcache ./cmd/kube-httpcache
COPY ./pkg ./pkg
RUN CGO_ENABLED=0 GOOS=linux \
    go build -ldflags="-s -w" -o kube-httpcache ./cmd/kube-httpcache

###############
# Stage 2: Build Prometheus Varnish Exporter (Optimized)
###############
FROM registry.redhat.io/rhel8/go-toolset:$__GO_VERSION__ AS builder-exporter
USER 0
ARG EXPORTER_VERSION=$PROM_EXPORTER_VERSION
WORKDIR /workspace
RUN yum install -y git --setopt=tsflags=nodocs && \
    git clone https://github.com/jonnenauha/prometheus_varnish_exporter.git --branch $PROM_EXPORTER_VERSION --depth 1 && \
    cd prometheus_varnish_exporter && \
    go build -ldflags="-s -w" -o /workspace/prometheus_varnish_exporter && \
    yum remove -y git && \
    yum clean all && \
    rm -rf /var/cache/yum /tmp/* /var/tmp/* /workspace/prometheus_varnish_exporter/.git

###############
# Stage 3: Final Slim Image
###############
FROM registry.redhat.io/ubi9/ubi:$__UBI_TAG__ AS final
USER 0

ARG VARNISH_REPO_VERSION=77
ARG VARNISH_VERSION=7.7.0
ARG VARNISH_RELEASE=1
ARG VARNISH_ARCH=el9.x86_64

# Install minimal requirements
RUN yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm && \
    yum install -y jemalloc && \
    curl -s https://packagecloud.io/install/repositories/varnishcache/varnish${VARNISH_REPO_VERSION}/script.rpm.sh | bash && \
    yum install -y varnish-${VARNISH_VERSION}-${VARNISH_RELEASE}.${VARNISH_ARCH} && \
    yum clean all && \
    rm -rf /var/cache/yum /tmp/* /var/tmp/* && \
    mkdir -p /exporter && chown -R 1001:0 /exporter

# Copy only necessary binaries
COPY --from=builder /workspace/kube-httpcache /kube-httpcache
RUN chown 1001:0 /kube-httpcache && chmod 0555 /kube-httpcache
COPY --from=builder-exporter /workspace/prometheus_varnish_exporter /exporter/
RUN chown 1001:0 /exporter/prometheus_varnish_exporter && chmod 0555 /exporter/prometheus_varnish_exporter

USER 1001
ENTRYPOINT ["/kube-httpcache"]