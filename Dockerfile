# syntax=docker/dockerfile:1

ARG DEBIAN_RELEASE=bookworm
ARG RUBY_VERSION=3.4

FROM ruby:${RUBY_VERSION}-slim-${DEBIAN_RELEASE} AS build

WORKDIR /src

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        make \
        tar \
    && rm -rf /var/lib/apt/lists/*

COPY . .

RUN make deps \
    && make -j"$(nproc)" LTO=0 all \
    && make PREFIX=/usr/local install

FROM debian:${DEBIAN_RELEASE}-slim AS runtime

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        gcc \
        libc6-dev \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /usr/local/lib/spinel /usr/local/lib/spinel
RUN rm -f /usr/local/lib/spinel/spinel_codegen.rb \
    && ln -sf /usr/local/lib/spinel/spinel /usr/local/bin/spinel

WORKDIR /work
ENTRYPOINT ["spinel"]
