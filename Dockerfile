FROM archlinux:latest AS builder

WORKDIR /src
COPY vieter ./vieter
COPY Makefile ./

RUN pacman \
        -Syu --noconfirm --needed \
        gcc git openssl make && \
    make customv && \
    jjr-v/v -prod vieter


FROM archlinux:latest

ENV REPO_DIR=/data

COPY --from=builder /src/vieter/vieter /usr/local/bin/

ENTRYPOINT [ "/usr/local/bin/vieter" ]
