#!/usr/bin/env bash
set -e

wget https://vyos.tnyzeq.icu/apt/apt.gpg.key -O /tmp/apt.gpg.key

rm -rf vyos-build/
git clone -b equuleus --single-branch https://github.com/vyos/vyos-build.git

version="1.3.x"

docker pull vyos/vyos-build:equuleus
docker run --rm --privileged --name="vyos-build" -v ./vyos-build/:/vyos -e GOSU_UID=$(id -u) -e GOSU_GID=$(id -g) \
    --sysctl net.ipv6.conf.lo.disable_ipv6=0 -v "/tmp/apt.gpg.key:/opt/apt.gpg.key" -w /vyos vyos/vyos-build:equuleus \
    sudo --preserve-env ./configure \
        --architecture amd64 \
        --build-by "self@local.com" \
        --build-type release \
        --debian-mirror http://deb.freexian.com/extended-lts \
        --version "$version" \
        --vyos-mirror "https://vyos.tnyzeq.icu/apt/equuleus" \
        --custom-apt-key /opt/apt.gpg.key \
        --custom-package "vyos-1x-smoketest"

docker run --rm --privileged --name="vyos-build" -v ./vyos-build/:/vyos -e GOSU_UID=$(id -u) -e GOSU_GID=$(id -g) \
    --sysctl net.ipv6.conf.lo.disable_ipv6=0 -v "/tmp/apt.gpg.key:/opt/apt.gpg.key" -w /vyos vyos/vyos-build:equuleus \
    sudo make iso

if [ -f vyos-build/build/live-image-amd64.hybrid.iso ]; then
    iso="vyos-$version-amd64.iso"
    cp vyos-build/build/live-image-amd64.hybrid.iso "$iso"
    echo "Build successful - $iso"
else
    >&2 echo "ERROR: ISO not found, something is wrong - see previous messages for what failed"
    exit 1
fi
