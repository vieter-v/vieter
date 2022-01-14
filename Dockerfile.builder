FROM alpine:3.12

LABEL maintainer="spytheman <spytheman@bulsynt.org>"

WORKDIR /opt/vlang

ENV VVV  /opt/vlang
ENV PATH /opt/vlang:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV VFLAGS -cc gcc

RUN mkdir -p /opt/vlang && \
  ln -s /opt/vlang/v /usr/bin/v && \
  apk --no-cache add \
    git make upx gcc bash \
    musl-dev \
    openssl-libs-static openssl-dev \
    zlib-static bzip2-static xz-dev expat-static zstd-static lz4-static \
    sqlite-static sqlite-dev \
    libx11-dev glfw-dev freetype-dev \
    libarchive-static libarchive-dev \
    diffutils

COPY . /vlang-local

RUN git clone \
      'https://github.com/ChewingBever/v/' \
      -b vweb-streaming \
      --single-branch \
      '/opt/vlang' && \
    rm -rf '/vlang-local' && \
    make && v -version

CMD ["v"]
