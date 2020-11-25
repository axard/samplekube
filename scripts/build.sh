#!/bin/sh

if [ -z "${OS:-}" ]; then
    echo "OS must be set"
    exit 1
fi
if [ -z "${ARCH:-}" ]; then
    echo "ARCH must be set"
    exit 1
fi
if [ -z "${VERSION:-}" ]; then
    echo "VERSION must be set"
    exit 1
fi

export CGO_ENABLED=0
export GOARCH="${ARCH}"
export GOOS="${OS}"
export GO111MODULE=on

go install                                                                                         \
   -installsuffix "static"                                                                         \
   -ldflags "-X $(go list -m)/internal/version.Version=${VERSION}"                                 \
   ./...
