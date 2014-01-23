#!/bin/sh
export KERNELDIR=`readlink -f .`
export PARENT_DIR=`readlink -f ..`
export INITRAMFS_DEST=$KERNELDIR/kernel/usr/initramfs
export INITRAMFS_SOURCE=/home/mahdi/kernels/flo/ramdisk/mahdi-4.4
export PACKAGEDIR=$KERNELDIR/Packages/exp
export ARCH=arm
export SUBARCH=arm
echo "Setting compiler toolchain..."
export CROSS_COMPILE=/home/mahdi/kernels/toolchain/arm-eabi-4.7/bin/arm-eabi-

time_start=$(date +%s.%N)

echo "Remove old Package Files"
rm -rf $PACKAGEDIR/* > /dev/null 2>&1
echo "Setup Package Directory"
mkdir -p $PACKAGEDIR/system/lib/hw
#mkdir -p $PACKAGEDIR/system/etc/init.d

echo "Create initramfs dir"
mkdir -p $INITRAMFS_DEST

echo "Remove old initramfs dir"
rm -rf $INITRAMFS_DEST/* > /dev/null 2>&1
echo "Copy new initramfs dir"
cp -R $INITRAMFS_SOURCE/* $INITRAMFS_DEST

echo "chmod initramfs dir"
chmod -R g-w $INITRAMFS_DEST/*
rm $(find $INITRAMFS_DEST -name EMPTY_DIRECTORY -print) > /dev/null 2>&1
rm -rf $(find $INITRAMFS_DEST -name .git -print)

echo "Remove old zImage"
rm $PACKAGEDIR/zImage > /dev/null 2>&1
rm arch/arm/boot/zImage > /dev/null 2>&1

echo "Make the kernel"
make flo_defconfig
echo "Lets Start!"
make -j`grep 'processor' /proc/cpuinfo | wc -l` 

echo "Copy PowerHal"
cp Packages/power.msm8960.so $PACKAGEDIR/system/lib/hw/power.msm8960.so
#cp Packages/power.msm8960.so $PACKAGEDIR/system/lib/hw/power.default.so

if [ -e $KERNELDIR/arch/arm/boot/zImage ]; then
	echo "Copy zImage to Package"
	cp arch/arm/boot/zImage $PACKAGEDIR/zImage

	echo "Make boot.img"
	./mkbootfs $INITRAMFS_DEST | gzip > $PACKAGEDIR/ramdisk.gz
	./mkbootimg --cmdline 'cmdline = console=ttyHSL0,115200,n8 androidboot.hardware=flo user_debug=31 msm_rtb.filter=0x3F ehci-hcd.park=3' --kernel $PACKAGEDIR/zImage --ramdisk $PACKAGEDIR/ramdisk.gz --base 0x80200000 --pagesize 2048 --ramdisk_offset 0x02000000 --output $PACKAGEDIR/boot.img 
	export curdate=`date "+%d-%m-%Y"`
	cd $PACKAGEDIR
	cp -R ../META-INF .
	rm ramdisk.gz
	rm zImage
        rm -r ../Mahdi-Flo-exp-4.4.2-stock*.zip
	zip -r ../Mahdi-Flo-exp-4.4.2-stock-v0.1-$curdate.zip .
	cd $KERNELDIR
else
	echo "KERNEL DID NOT BUILD! no zImage exist"
fi;

time_end=$(date +%s.%N)
echo -e "${BLDYLW}Total time elapsed: ${TCTCLR}${TXTGRN}$(echo "($time_end - $time_start) / 60"|bc ) ${TXTYLW}minutes${TXTGRN} ($(echo "$time_end - $time_start"|bc ) ${TXTYLW}seconds) ${TXTCLR}"

