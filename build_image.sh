#!/bin/bash
################################################################
##
##
## Build Release Image
################################################################
set -e

if [ -z $ROOT ]; then
	ROOT=`cd .. && pwd`
fi

if [ -z $1 ]; then
	DISTRO="xineal"
else
	DISTRO=$1
fi

if [ -z $2 ]; then
	PLATFORM="rk3399"
else
	PLATFORM=$2
fi

if [ $3 = "1" ]; then
	IMAGETYPE="desktop"
	disk_size="3800"
else
	IMAGETYPE="server"
	disk_size="1200"
fi


BUILD="$ROOT/external"
TOOLPATH=${BUILD}/rkbin/tools
OUTPUT="$ROOT/output"
VER="v1.0"
IMAGENAME="OrangePi_${PLATFORM}_${DISTRO}_${IMAGETYPE}_${VER}.img"
IMAGE="$OUTPUT/images/$IMAGENAME"
ROOTFS="$OUTPUT/rootfs"
VAR=$4
PATH=$PATH:$TOOLPATH
source $ROOT/scripts/partitions.sh

if [ ! -d $OUTPUT/images ]; then
        mkdir -p $OUTPUT/images
fi

if [ -z "$disk_size" ]; then
	disk_size=100 #MiB
fi

if [ "$disk_size" -lt 60 ]; then
	echo "Disk size must be at least 60 MiB"
	exit 2
fi

echo "Generate System image : ${IMAGE} !"
dd if=/dev/zero of=${IMAGE} bs=1M count=0 seek=4000

parted -s ${IMAGE} mklabel gpt 
parted -s ${IMAGE} unit s mkpart loader1 ${LOADER1_START} $(expr ${RESERVED1_START} - 1)
parted -s ${IMAGE} unit s mkpart reserved1 ${RESERVED1_START} $(expr ${RESERVED2_START} - 1)
parted -s ${IMAGE} unit s mkpart reserved2 ${RESERVED2_START} $(expr ${LOADER2_START} - 1)
parted -s ${IMAGE} unit s mkpart loader2 ${LOADER2_START} $(expr ${ATF_START} - 1)
parted -s ${IMAGE} unit s mkpart atf ${ATF_START} $(expr ${BOOT_START} - 1)
parted -s ${IMAGE} unit s mkpart boot ${BOOT_START} $(expr ${ROOTFS_START} - 1)
parted -s ${IMAGE} set 6 boot on
parted -s ${IMAGE} unit s mkpart rootfs ${ROOTFS_START} 100%
ROOT_UUID="B921B045-1DF0-41C3-AF44-4C6F280D3FAE"
	gdisk ${IMAGE} <<EOF
x
c
7
${ROOT_UUID}
w
y
EOF


# burn u-boot
dd if=${OUTPUT}/u-boot/idbloader.img of=${IMAGE} seek=${LOADER1_START} conv=notrunc
dd if=${OUTPUT}/u-boot/uboot.img of=${IMAGE} seek=${LOADER2_START} conv=notrunc
dd if=${OUTPUT}/u-boot/trust.img of=${IMAGE} seek=${ATF_START} conv=notrunc


# Create additional ext4 file system for rootfs
rootfs_size=$((disk_size-128))  # $disk_size - $ROOTFS_START*512 / 1024 / 1024
dd if=/dev/zero bs=1M count=$rootfs_size of=${IMAGE}2
mkfs.ext4 -F -b 4096 -E stride=2,stripe-width=1024 -L rootfs ${IMAGE}2

if [ ! -d /media/tmp ]; then
    mkdir -p /media/tmp
fi

mount -t ext4 ${IMAGE}2 /media/tmp

# Add rootfs into Image
cp -rfa $OUTPUT/rootfs/* /media/tmp
# Add wifi firmware
cp -rfa $ROOT/external/system/ /media/tmp 
umount /media/tmp

./Generate_boot_image.sh $VAR
# burn boot image
dd if=${OUTPUT}/boot.img of=${IMAGE} conv=notrunc seek=${BOOT_START}

# burn rootfs image
dd if=${IMAGE}2 of=${IMAGE} seek=${ROOTFS_START}


cd $OUTPUT/images/ 
rm -rf ${IMAGENAME}.tar.gz
md5sum ${IMAGENAME} > ${IMAGENAME}.md5sum
tar czvf  ${IMAGENAME}.tar.gz $IMAGENAME*
rm -f ${IMAGENAME}.md5sum

sync
clear
