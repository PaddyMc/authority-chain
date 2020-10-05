FROM golang:alpine AS build-env

RUN apk update
RUN apk add --no-cache curl make git libc-dev bash gcc linux-headers eudev-dev python3

WORKDIR /go/src/github.com/PaddyMc/authority-chain

COPY . .

RUN make install

## Final image
FROM golang:alpine

## Install ca-certificates
RUN apk add --update ca-certificates curl
WORKDIR /root

COPY --from=build-env /go/bin/authority-chaind /usr/bin/authority-chaind
COPY --from=build-env /go/bin/authority-chaincli /usr/bin/authority-chaincli

EXPOSE 26656 26657 1317 9090

