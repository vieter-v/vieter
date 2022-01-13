FROM chewingbever/vlang:latest AS builder

WORKDIR /app

# Copy over source code & build production binary
COPY src ./src
COPY Makefile ./
RUN make prod


FROM alpine:3.15

ENV REPO_DIR=/data

RUN apk update && \
    apk add --no-cache \
        libarchive

COPY --from=builder /app/pvieter /usr/local/bin/vieter

ENTRYPOINT [ "/usr/local/bin/vieter" ]
