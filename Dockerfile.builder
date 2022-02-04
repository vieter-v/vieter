FROM alpine:3.12

ARG TARGETPLATFORM

WORKDIR /opt/vlang

ENV VVV  /opt/vlang
ENV PATH /opt/vlang:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV VFLAGS -cc gcc
ENV V_PATH /opt/vlang/v

RUN ln -s /opt/vlang/v /usr/bin/v && \
  apk --no-cache add \
    git make gcc curl openssl \
    musl-dev \
    openssl-libs-static openssl-dev \
    zlib-static bzip2-static xz-dev expat-static zstd-static lz4-static \
    sqlite-static sqlite-dev \
    libx11-dev glfw-dev freetype-dev \
    libarchive-static libarchive-dev \
    gc-dev \
    diffutils

COPY patches ./patches
COPY Makefile ./

RUN make v && \
  mv v-*/* /opt/vlang && \
  v -version

RUN if [ "$TARGETPLATFORM" = 'linux/amd64' ]; then \
  wget -O /usr/local/bin/mc https://dl.min.io/client/mc/release/linux-amd64/mc && \
  chmod +x /usr/local/bin/mc ; \
fi

CMD ["v"]
