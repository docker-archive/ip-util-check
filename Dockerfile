FROM golang:1.11-alpine as build-swarmctl
WORKDIR /go/src/github.com/docker

RUN apk add --no-cache --update bash ca-certificates curl make git openssh-client
RUN git clone https://github.com/docker/swarmkit.git swarmkit && cd swarmkit && make bin/swarmctl && cp bin/swarmctl /usr/bin/swarmctl && rm -rf /go/src/github.com/docker/swarmkit

FROM alpine:3.9 as build-protoc
ARG PROTOC_VERSION=3.6.1
RUN apk add --update --no-cache unzip curl
# download and install protoc binary and .proto files
RUN curl --silent --show-error --location --output protoc.zip \
  https://github.com/google/protobuf/releases/download/v$PROTOC_VERSION/protoc-$PROTOC_VERSION-linux-x86_64.zip \
  && unzip -d /usr/local protoc.zip include/\* bin/\* \
  && rm -f protoc.zip

FROM alpine:3.9 as build-docker
ARG DOCKER_CLIENT_VERSION=18.09.1
RUN apk add --update --no-cache curl
RUN curl -SsL --output docker.tgz \
  https://download.docker.com/linux/static/stable/x86_64/docker-$DOCKER_CLIENT_VERSION.tgz \
  && tar xvzf docker.tgz \
  && cp docker/docker /usr/bin/docker \
  && rm -f docker.tgz

FROM alpine:3.9
RUN apk add --no-cache --update bash jq
# WORKDIR /go/src/github.com/docker
# RUN git clone https://github.com/docker/swarmkit.git swarmkit && cd swarmkit && make bin/swarmctl && cp bin/swarmctl /usr/bin/swarmctl && rm -rf /go/src/github.com/docker/swarmkit
COPY --from=build-swarmctl /usr/bin/swarmctl /usr/bin
COPY --from=build-protoc /usr/local/. /usr/local
COPY --from=build-docker /usr/bin/docker /usr/bin
COPY ip-util-check /usr/bin
CMD [ "/usr/bin/ip-util-check" ]
