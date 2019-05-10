#!/bin/bash -e

LOCALPATH=`cd .. && pwd`
OUT=${LOCALPATH}/output
TOOLPATH=${LOCALPATH}/external/rkbin/tools
EXTLINUXPATH=${LOCALPATH}/external/extlinux
CHIP=""
TARGET=""
SIZE=""
ROOTFS_PATH=""

PATH=$PATH:$TOOLPATH

source $LOCALPATH/scripts/partitions.sh

usage() {
	echo -e "\nUsage: ./mk-image.sh -c rk3399 -t system -s 4000 -r ../output/rootfs.img \n"
	echo -e "       ./mk-image.sh -c rk3399 -t boot -f emmc/sd\n"
}
finish() {
	echo -e "\e[31m MAKE IMAGE FAILED.\e[0m"
	exit -1
}
trap finish ERR

OLD_OPTIND=$OPTIND
while getopts "c:t:s:r:f:" flag; do
	case $flag in
		c)
			CHIP="$OPTARG"
			;;
		t)
			TARGET="$OPTARG"
			;;
		s)
			SIZE="$OPTARG"
			if [ $SIZE -le 120 ]; then
				echo -e "\e[31m SYSTEM IMAGE SIZE TOO SMALL \e[0m"
				exit -1
			fi
			;;
		r)
			ROOTFS_PATH="$OPTARG"
			;;
		f)
			FLASH="$OPTARG"
			if [ $FLASH = "emmc" ]; then
				NUM="1"
			elif [ $FLASH = "sd" ]; then
				NUM="0"
			fi		
			;;
	esac
done
OPTIND=$OLD_OPTIND

#if [ ! -f "${EXTLINUXPATH}/${CHIP}.conf" ]; then
	#CHIP="rk3288"
#fi

if [ ! $CHIP ] && [ ! $TARGET ]; then
	usage
	exit
fi

generate_boot_image() {
	BOOT=${OUT}/boot.img
	rm -rf ${BOOT}

	echo -e "\e[36m Generate Boot image start\e[0m"

	# 100 Mb
	mkfs.vfat -n "boot" -S 512 -C ${BOOT} $((100 * 1024))

	mmd -i ${BOOT} ::/extlinux
	mcopy -i ${BOOT} -s ${EXTLINUXPATH}/${CHIP}.conf ::/extlinux/extlinux.conf
	mcopy -i ${BOOT} -s ${OUT}/kernel/* ::

	echo -e "\e[36m Generate Boot image : ${BOOT} success! \e[0m"
}

generate_system_image() {
	if [ ! -f "${OUT}/boot.img" ]; then
		echo -e "\e[31m CAN'T FIND BOOT IMAGE \e[0m"
		usage
		exit
	fi

	if [ ! -f "${ROOTFS_PATH}" ]; then
		echo -e "\e[31m CAN'T FIND ROOTFS IMAGE \e[0m"
		usage
		exit
	fi

	SYSTEM=${OUT}/system.img
	rm -rf ${SYSTEM}

	echo "Generate System image : ${SYSTEM} !"

	dd if=/dev/zero of=${SYSTEM} bs=1M count=0 seek=$SIZE

	parted -s ${SYSTEM} mklabel gpt
	parted -s ${SYSTEM} unit s mkpart loader1 ${LOADER1_START} $(expr ${RESERVED1_START} - 1)
	parted -s ${SYSTEM} unit s mkpart reserved1 ${RESERVED1_START} $(expr ${RESERVED2_START} - 1)
	parted -s ${SYSTEM} unit s mkpart reserved2 ${RESERVED2_START} $(expr ${LOADER2_START} - 1)
	parted -s ${SYSTEM} unit s mkpart loader2 ${LOADER2_START} $(expr ${ATF_START} - 1)
	parted -s ${SYSTEM} unit s mkpart atf ${ATF_START} $(expr ${BOOT_START} - 1)
	parted -s ${SYSTEM} unit s mkpart boot ${BOOT_START} $(expr ${ROOTFS_START} - 1)
	parted -s ${SYSTEM} set 6 boot on
	parted -s ${SYSTEM} unit s mkpart rootfs ${ROOTFS_START} 100%

	if [ "$CHIP" == "rk3328" ] || [ "$CHIP" == "rk3399" ]; then
		ROOT_UUID="B921B045-1DF0-41C3-AF44-4C6F280D3FAE"
	else
		ROOT_UUID="69DAD710-2CE4-4E3C-B16C-21A1D49ABED3"
	fi

	gdisk ${SYSTEM} <<EOF
x
c
7
${ROOT_UUID}
w
y
EOF

	# burn u-boot
	if [ "$CHIP" == "rk3288" ] || [ "$CHIP" == "rk322x" ] || [ "$CHIP" == "rk3036" ]; then
		dd if=${OUT}/u-boot/idbloader.img of=${SYSTEM} seek=${LOADER1_START} conv=notrunc
	elif [ "$CHIP" == "rk3399" ]; then
		dd if=${OUT}/u-boot/idbloader.img of=${SYSTEM} seek=${LOADER1_START} conv=notrunc

		dd if=${OUT}/u-boot/uboot.img of=${SYSTEM} seek=${LOADER2_START} conv=notrunc
		dd if=${OUT}/u-boot/trust.img of=${SYSTEM} seek=${ATF_START} conv=notrunc
	elif [ "$CHIP" == "rk3328" ]; then
		dd if=${OUT}/u-boot/idbloader.img of=${SYSTEM} seek=${LOADER1_START} conv=notrunc

		dd if=${OUT}/u-boot/uboot.img of=${SYSTEM} seek=${LOADER2_START} conv=notrunc
		dd if=${OUT}/u-boot/trust.img of=${SYSTEM} seek=${ATF_START} conv=notrunc
	fi

	# burn boot image
	dd if=${OUT}/boot.img of=${SYSTEM} conv=notrunc seek=${BOOT_START}

	# burn rootfs image
	dd if=${ROOTFS_PATH} of=${SYSTEM} seek=${ROOTFS_START}
}

if [ "$TARGET" = "boot" ]; then
	./Generate_boot_image.sh $NUM
elif [ "$TARGET" == "system" ]; then
	generate_system_image
fi
