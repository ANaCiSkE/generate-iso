#!/bin/bash
set -e

wget https://vyos.tnyzeq.icu/apt/apt.gpg.key -O /tmp/apt.gpg.key

rm -rf vyos-build/
git clone https://github.com/dd010101/vyos-build.git
git -C vyos-build/ checkout sagitta

version="1.4.x"

docker pull vyos/vyos-build:sagitta
docker run --rm --privileged --name="vyos-build" -v ./vyos-build/:/vyos -e GOSU_UID=$(id -u) -e GOSU_GID=$(id -g) \
    --sysctl net.ipv6.conf.lo.disable_ipv6=0 -v "/tmp/apt.gpg.key:/opt/apt.gpg.key" -w /vyos vyos/vyos-build:sagitta \
    sudo --preserve-env ./build-vyos-image iso \
        --architecture amd64 \
        --build-by "self@local.com" \
        --build-type release \
        --debian-mirror http://deb.debian.org/debian/ \
        --version "$version" \
        --vyos-mirror "https://vyos.tnyzeq.icu/apt/sagitta" \
        --custom-apt-key /opt/apt.gpg.key \
        --custom-package "vyos-1x-smoketest"

if [ -f vyos-build/build/live-image-amd64.hybrid.iso ]; then
    iso="vyos-$version-iso-amd64.iso"
    cp vyos-build/build/live-image-amd64.hybrid.iso "$iso"
    echo "Build successful - $iso"
else
    ls -alsh vyos-build/build/
    >&2 echo "ERROR: ISO not found, something is wrong - see previous messages for what failed"
    exit 1
fi
