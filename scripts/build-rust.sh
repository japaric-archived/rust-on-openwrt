#!/bin/bash

# Run this in a Wheezy chroot with the following command:
#
# $ systemd-nspawn \
#     su -c /on-openwrt/scripts/build-rust.sh rustbuild

set -x
set -e

: ${DIST_DIR:=~/dist}
: ${DROPBOX:=dropbox_uploader.sh}
: ${SDK_DIR:=/sdk}
: ${SRC_DIR:=~/src}
: ${TARGET:=mips-unknown-linux-gnu}

# Update source to upstream
cd $SRC_DIR
git checkout .
git checkout master
git pull

# Optionally checkout older hash
git checkout $1
git submodule update

# apply patch to remove -mno-compact-eh flag
git apply /on-openwrt/scripts/remove-mno-compact-eh-flag.patch

# Check that the OpenWRT toolchain works
cd $SDK_DIR
export STAGING_DIR=$PWD/staging_dir
export PATH=$PWD/$(echo staging_dir/toolchain-*/bin):$PATH
mips-openwrt-linux-gcc -v

# Get information about HEAD
cd $SRC_DIR
HEAD_HASH=$(git rev-parse --short HEAD)
HEAD_DATE=$(TZ=UTC date -d @$(git show -s --format=%ct HEAD) +'%Y-%m-%d')
TARBALL=rust-$HEAD_DATE-$HEAD_HASH-$TARGET

# build it
cd build
../configure \
  --disable-docs \
  --enable-ccache \
  --prefix=/ \
  --target=$TARGET
make clean
make -j$(nproc)

# package
rm -rf $DIST_DIR/*
DESTDIR=$DIST_DIR make install
cd $DIST_DIR/lib/rustlib
tar czf ~/$TARBALL $TARGET
cd ~
TARBALL_HASH=$(sha1sum $TARBALL | tr -s ' ' | cut -d ' ' -f 1)
mv $TARBALL $TARBALL-$TARBALL_HASH.tar.gz
TARBALL=$TARBALL-$TARBALL_HASH.tar.gz

# ship it
if [ -z $DONTSHIP ]; then
  $DROPBOX -p upload $TARBALL .
fi
rm $TARBALL

# cleanup
rm -rf $DIST_DIR/*
