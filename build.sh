#!/usr/bin/env bash

platform='unknown'
unamestr=`uname`
if [[ "$unamestr" == 'Linux' ]]; then
   platform='linux'
elif [[ "$unamestr" == 'Darwin' ]]; then
   platform='darwin'
fi

#
if [ "$platform" == 'linux' ]; then
    export CCOMPILER=$PWD/bin_linuxx86/arm-eabi-4.4.3/bin/arm-eabi-
    export MKBOOTIMG=$PWD/bin_linuxx86/mkbootimg
elif [ "$platform" == 'darwin' ]; then
    export CCOMPILER=$PWD/bin_darwinx86/arm-eabi-4.4.3/bin/arm-eabi-
    export MKBOOTIMG=$PWD/bin_darwinx86/mkbootimg
else
    echo "Not supported platform!"
    exit 1
fi

#
rm -rf new-ramdisk.cpio.gz
rm -rf new_boot.img
rm -rf kernel/arch/arm/boot/zImage

#
if [ ! -e "kernel" ]; then
    git submodule update --init
fi
cd kernel
cp -f arch/arm/configs/hw01e_defconfig .config
make ARCH=arm CROSS_COMPILE=$CCOMPILER -j4
cd ..
if [ -e "./kernel/arch/arm/boot/zImage" ]; then
    cd boot_ramdisk
    find . | cpio -o -H newc | gzip > ../new-ramdisk.cpio.gz
    cd ..
    $MKBOOTIMG --kernel ./kernel/arch/arm/boot/zImage  --ramdisk ./new-ramdisk.cpio.gz --cmdline "androidboot.hardware=huawei user_debug=31 kgsl.mmutype=gpummu" --base 0x80200000 --pagesize 2048 --ramdisk_offset 0x1400000 -o new_boot.img
else
    echo "カーネルのビルドが失敗してるかもしれないよ"
    echo "kernel/arch/arm/boot/zImageが存在するか確認してちょうだい"
    exit 1
fi

exit 0
