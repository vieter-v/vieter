FROM chewingbever/vlang:latest AS builder

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
        LDFLAGS='-lz -lbz2 -llzma -lexpat -lzstd -llz4 -static' make prod && \
        mv pvieter vieter ; \
    fi


FROM busybox:1.35.0

ENV PATH=/bin \
    VIETER_REPO_DIR=/data/repo \
    VIETER_PKG_DIR=/data/pkgs \
    VIETER_DOWNLOAD_DIR=/data/downloads \
    VIETER_REPOS_FILE=/data/repos.json

COPY --from=builder /app/dumb-init /app/vieter /bin/

HEALTHCHECK --interval=30s \
    --timeout=3s \
    --start-period=5s \
    CMD /bin/wget --spider http://localhost:8000/health || exit 1

RUN mkdir /data && \
    chown -R www-data:www-data /data && \
    mkdir -p '/var/spool/cron/crontabs' && \
    echo '0 3 * * * /bin/vieter build' | crontab - 

WORKDIR /data

USER www-data:www-data

ENTRYPOINT ["/bin/dumb-init", "--"]
CMD ["/bin/vieter", "server"]
