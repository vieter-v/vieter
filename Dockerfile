FROM thevlang/vlang:alpine-dev AS builder

WORKDIR /src
COPY vieter ./vieter

RUN v -prod vieter


FROM alpine:3.15.0

ENV REPO_DIR=/data

COPY --from=builder /src/vieter/vieter /usr/local/bin/

ENTRYPOINT [ "/usr/local/bin/vieter" ]
