# version: 1.1
#    desc: build minio/minfs and docker volume plugin
#  author: Thorsten Schifferdecker <ts@systs.org>, 2017
# license: Apache License 2.0

# we use alpine as base
FROM alpine:latest as dev-container

# set some vars
ENV GOPATH=/go
ENV GITPATH=$GOPATH/src/github.com/minio

# build development container
ENV STAGE1=20180110-1

RUN set -eux; \
	apk add --no-cache \
		bash \
		build-base \
		go \
		git \
		fuse-dev \
		sudo

ENV STAGE2=20170916-1
RUN mkdir -p $GITPATH \
	&& cd $GITPATH \
	&& git clone --depth=1 https://github.com/minio/minfs.git \
	&& cd minfs \
	&& make install || true \
	&& cd docker-plugin \
	&& go install --ldflags '-extldflags "-static"'

# build the plugin container with Multi-Stage Build
# see https://docs.docker.com/engine/userguide/eng-image/multistage-build/
FROM alpine:latest

LABEL authors="Thorsten Schifferdecker <ts@systs.org>"

RUN apk add --no-cache \
		ca-certificates \
		fuse \
	&& mkdir -p /run/docker/plugins

COPY --from=dev-container /go/bin/docker-plugin /usr/sbin/minfs-docker-plugin
COPY --from=dev-container /sbin/minfs /sbin/minfs
COPY --from=dev-container /sbin/mount.minfs /sbin/mount.minfs
COPY --from=dev-container /go/src/github.com/minio/minfs/docker-plugin/config.json /tmp/config.json

# no need for CMD or ENTRYPOINT, default is used

# eof
