#!/bin/bash

# Setup Proton-Clang
if [ ! -d $(pwd)/toolchain/proton-clang ]; then
        git config --global advice.detachedHead false
        git clone --depth=1 https://github.com/kdrag0n/proton-clang -b master ./toolchains/proton-clang
else
    echo "This $(pwd)/toolchain/proton-clang already exists."
fi


# Install Packages (In case your server don't have this pre-installed)
# Run `sudo apt-get update -y` as well.
echo "Updating build environment..."
sudo apt-get update -y
echo "Update done."

echo "Installing necessary packages..."
sudo apt-get install git ccache automake flex lzop bison gperf build-essential zip curl zlib1g-dev g++-multilib libxml2-utils bzip2 libbz2-dev libbz2-1.0 libghc-bzlib-dev squashfs-tools pngcrush schedtool dpkg-dev liblz4-tool make optipng maven libssl-dev pwgen libswitch-perl policycoreutils minicom libxml-sax-base-perl libxml-simple-perl bc libc6-dev-i386 lib32ncurses5-dev libx11-dev lib32z-dev libgl1-mesa-dev xsltproc unzip device-tree-compiler python2 python3 device-tree-compiler -y
echo "Package installation done."

# Exports
export PATH="$(pwd)/toolchains/proton-clang/bin:$PATH"

make -C $(pwd) O=$(pwd)/out CC=clang ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_COMPAT=arm-linux-androideabi- LD=ld.lld vendor/bengal-perf_defconfig
make -C $(pwd) O=$(pwd)/out CC=clang ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_COMPAT=arm-linux-androideabi- LD=ld.lld -j$(nproc --all)

# Final Build
mkdir -p kernelbuild
echo "Copying Image into kernelbuild..."
cp -nf $(pwd)/out/arch/arm64/boot/Image.gz $(pwd)/kernelbuild
echo "Done copying Image/.gz into kernelbuild."

mkdir -p modulebuild
echo "Copying modules into modulebuild..."
cp -nr $(find out -name '*.ko') $(pwd)/modulebuild
echo "Stripping debug symbols from modules..."
$(pwd)/toolchain/proton-clang/bin/llvm-strip --strip-debug $(pwd)/modulebuild/*.ko
echo "Done copying modules into modulebuild."

# AnyKernel3 Support
cp -nf $(pwd)/kernelbuild/Image.gz $(pwd)/AnyKernel3
cp -nr $(pwd)/modulebuild/*.ko $(pwd)/AnyKernel3/modules/system/lib/modules
cd AnyKernel3 && zip -r9 UPDATE-AnyKernel3-gta9.zip * -x .git README.md *placeholder
