#!/usr/bin/env bash

HUGO_VERSION=${1:-"none"}

set -e

export DEBIAN_FRONTEND=noninteractive

# Check the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "The script must be run as root. Use sudo, su, or add \"USER root\" to your Dockerfile before running this script."
    exit 1
fi

if [ "${HUGO_VERSION}" != "none" ]; then
    echo "Extract Hugo ${HUGO_VERSION} ..."

    BUILD_PACKAGES="\
        dpkg-dev \
        gzip \
    "

    apt-get update
    apt-get install --no-install-recommends -y ${BUILD_PACKAGES}
    apt-get upgrade --no-install-recommends -y

    export ARCHITECTURE=""
    case "$(dpkg --print-architecture)" in
        amd64*)
            export ARCHITECTURE=64bit
        ;;
        arm64*)
            export ARCHITECTURE=ARM64
        ;;
        armhf*)
            export ARCHITECTURE=ARM
        ;;
        i386*)
            export ARCHITECTURE=32bit
        ;;
        *) echo "unsupported architecture"; exit 1 ;;
    esac

    curl -sSL -o /tmp/hugo.tar.gz https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_Linux-${ARCHITECTURE}.tar.gz
    curl -sSL -o /tmp/SHASUMS256.txt https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_checksums.txt

    cat /tmp/SHASUMS256.txt | grep "$(sha256sum /tmp/hugo.tar.gz | cut -d ' ' -f 1)"

    mkdir -p /tmp/hugo
    tar -vxzf /tmp/hugo.tar.gz -C /tmp/hugo
    cp -v /tmp/hugo/hugo /usr/local/bin/hugo

    rm -vrf /tmp/hugo /tmp/SHASUMS256.txt /tmp/hugo.tar.xz
fi

echo "Done!"