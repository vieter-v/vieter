FROM chewingbever/vlang:latest AS builder

WORKDIR /app

# Copy over source code & build production binary
COPY src ./src
COPY Makefile ./

ENV LDFLAGS='-lz -lbz2 -llzma -lexpat -lzstd -llz4 -static'
RUN v -o pvieter -clags "-O3" src


FROM alpine:3.15

ENV REPO_DIR=/data

COPY --from=builder /app/pvieter /usr/local/bin/vieter

ENTRYPOINT [ "/usr/local/bin/vieter" ]
