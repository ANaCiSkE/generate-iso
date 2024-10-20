#!/usr/bin/env bash
set -e

wget https://vyos.tnyzeq.icu/apt/apt.gpg.key -O /tmp/apt.gpg.key

rm -rf vyos-build/
git clone -b circinus --single-branch https://github.com/vyos/vyos-build.git

# temporary workaround for broken generic flavor
sed -i 's/vyos-xe-guest-utilities/xen-guest-agent/' vyos-build/data/build-flavors/generic.toml

version="1.5.x"

docker pull vyos/vyos-build:circinus
docker run --rm --privileged --name="vyos-build" -v ./vyos-build/:/vyos -e GOSU_UID=$(id -u) -e GOSU_GID=$(id -g) \
    --sysctl net.ipv6.conf.lo.disable_ipv6=0 -v "/tmp/apt.gpg.key:/opt/apt.gpg.key" -w /vyos vyos/vyos-build:circinus \
    sudo --preserve-env ./build-vyos-image generic \
        --architecture amd64 \
        --build-by "self@local.com" \
        --build-type release \
        --debian-mirror http://deb.debian.org/debian/ \
        --version "$version" \
        --vyos-mirror "https://vyos.tnyzeq.icu/apt/circinus" \
        --custom-apt-key /opt/apt.gpg.key \
        --custom-package "vyos-1x-smoketest"

if [ -f vyos-build/build/live-image-amd64.hybrid.iso ]; then
    iso="vyos-$version-amd64.iso"
    cp vyos-build/build/live-image-amd64.hybrid.iso "$iso"
    echo "Build successful - $iso"
else
    >&2 echo "ERROR: ISO not found, something is wrong - see previous messages for what failed"
    exit 1
fi
