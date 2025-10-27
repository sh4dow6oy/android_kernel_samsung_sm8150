#!/bin/bash
set -e
exec 9>.kernelsu-fetch-lock
flock -n 9 || exit 0
[[ $(( $(date +%s) - $(stat -c %Y "drivers/kernelsu/.check" 2>/dev/null || echo 0) )) -gt 86400 ]] || exit 0

AUTHOR="KernelSU-Next"
REPO="KernelSU-Next"
VERSION=`curl -s -I -k "https://api.github.com/repos/$AUTHOR/$REPO/commits?per_page=1" | sed -n '/^[Ll]ink:/ s/.*"next".*page=\([0-9]*\).*"last".*/\1/p'`
TAG=`curl -s https://api.github.com/repos/$AUTHOR/$REPO/tags | jq -r '.[0].name'`

if [[ -f drivers/kernelsu/.version && *$(cat drivers/kernelsu/.version)* == *$VERSION* ]]; then
	touch drivers/kernelsu/.check
	exit 0
fi

# printf "$REPO updating to $((10000+$VERSION+200))\n"
rm -rf drivers/kernelsu
mkdir -p drivers/kernelsu
cd drivers/kernelsu
wget -q -O - https://github.com/$AUTHOR/$REPO/archive/refs/heads/next.tar.gz | tar -xz --strip=2 "$REPO-next/kernel"
echo $VERSION >> .version
touch .check

# You can patch for your kernel here
echo "" >> Makefile
sed -i '/warning /d' Makefile
sed -i '/DKSU_VERSION/d' Makefile
echo "ccflags-y += -DKSU_VERSION=$((10000 + $VERSION + 200))" >> Makefile
echo "ccflags-y += -DKSU_VERSION_TAG=\\\"$TAG\\\"" >> Makefile