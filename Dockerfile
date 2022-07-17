FROM chewingbever/vlang:0.3 AS builder

ARG TARGETPLATFORM
ARG CI_COMMIT_SHA
ARG DI_VER=1.2.5

WORKDIR /app

# Build dumb-init
RUN curl -Lo - "https://github.com/Yelp/dumb-init/archive/refs/tags/v${DI_VER}.tar.gz" | tar -xzf - && \
    cd "dumb-init-${DI_VER}" && \
    make SHELL=/bin/sh && \
    mv dumb-init .. && \
    cd ..

# Copy over source code & build production binary
COPY src ./src
COPY Makefile ./

RUN if [ -n "${CI_COMMIT_SHA}" ]; then \
        curl --fail \
            -o vieter \
            "https://s3.rustybever.be/vieter/commits/${CI_COMMIT_SHA}/vieter-$(echo "${TARGETPLATFORM}" | sed 's:/:-:g')" && \
            chmod +x vieter ; \
    else \
        LDFLAGS='-lz -lbz2 -llzma -lexpat -lzstd -llz4 -lsqlite3 -static' make prod && \
        mv pvieter vieter ; \
    fi


FROM busybox:1.35.0

ENV PATH=/bin \
    VIETER_DATA_DIR=/data \
    VIETER_PKG_DIR=/data/pkgs

COPY --from=builder /app/dumb-init /app/vieter /bin/

RUN mkdir /data && \
    chown -R www-data:www-data /data

WORKDIR /data

USER www-data:www-data

ENTRYPOINT ["/bin/dumb-init", "--"]
CMD ["/bin/vieter", "server"]
