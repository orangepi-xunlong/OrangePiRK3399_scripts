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

BUILD="$ROOT/external"
TOOLPATH=${BUILD}/rkbin/tools
OUTPUT="$ROOT/output"
IMAGENAME="system.img"
IMAGE="$OUTPUT/$IMAGENAME"
ROOTFS="$OUTPUT/rootfs.img"
VAR=$1
PATH=$PATH:$TOOLPATH
EXTLINUXPATH=$BUILD/extlinux

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

if [ ! -f $ROOT/output/u-boot/idbloader.img -o ! -f $ROOT/output/u-boot/trust.img -o ! -f $ROOT/output/u-boot/uboot.img ]; then 
	echo "Can't find uboot in $OUTPUT"
	exit 0
fi
if [ ! -f $OUTPUT/rootfs.img ]; then
	echo "Can not find rootfs.img in $OUTPUT"
	exit 0
fi
	./Generate_boot_image.sh $VAR


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

# burn boot image
dd if=${OUTPUT}/boot.img of=${IMAGE} conv=notrunc seek=${BOOT_START}

# burn rootfs image
dd if=$ROOTFS of=${IMAGE} seek=${ROOTFS_START}


sync
clear
