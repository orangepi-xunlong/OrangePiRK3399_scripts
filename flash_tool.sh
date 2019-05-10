#!/bin/bash -e

if [ -z $ROOT ]; then
	ROOT=`cd .. && pwd`
fi
LOCALPATH=$ROOT
OUT=${LOCALPATH}/output
TOOLPATH=${LOCALPATH}/external/rkbin/tools
EXTLINUXPATH=${LOCALPATH}/external/extlinux
CHIP=""
DEVICE=""
IMAGE=""
DEVICE=""
SEEK=""

PATH=$PATH:$TOOLPATH

source $LOCALPATH/scripts/partitions.sh

usage() {
	echo -e "\nUsage: emmc: ./flash_tool.sh -c rk3399  -p system -i ../output/system.img  \n"
	echo -e "       sdcard: ./flash_tool.sh -c rk3399  -d /dev/sdb -p system  -i ../output/system.img \n"
}

finish() {
	echo -e "\e[31m FLASH IMAGE FAILED.\e[0m"
	exit -1
}
trap finish ERR

while getopts "c:t:s:d:p:r:d:i:h" flag; do
	case $flag in
		c)
			CHIP="$OPTARG"
			;;
		d)
			DEVICE="$OPTARG"
			;;
		i)
			IMAGE="$OPTARG"
			if [ ! -f "${IMAGE}" ]; then
				echo -e "\e[31m CAN'T FIND IMAGE \e[0m"
				usage
				exit
			fi
			;;
		p)
			PARTITIONS="$OPTARG"
			BPARTITIONS=$(echo $PARTITIONS | tr 'a-z' 'A-Z')
			SEEK=${BPARTITIONS}_START
			eval SEEK=\$$SEEK

			if [ -n "$(echo $SEEK | sed -n "/^[0-9]\+$/p")" ]; then
				echo "PARTITIONS OFFSET: $SEEK sectors."
			else
				echo -e "\e[31m INVAILD PARTITION.\e[0m"
				exit
			fi
			;;
	esac
done

if [ ! $IMAGE ]; then
	usage
	exit
fi

if [ ! -f "${EXTLINUXPATH}/${CHIP}.conf" ]; then
	CHIP="rk3288"
fi

flash_upgt() {
	if [ "${CHIP}" == "rk3288" ]; then
		sudo $TOOLPATH/rkdeveloptool db ${LOCALPATH}/external/rkbin/rk32/rk3288_ubootloader_*.bin
	elif [ "${CHIP}" == "rk322x" ]; then
		sudo $TOOLPATH/rkdeveloptool db ${LOCALPATH}/external/rkbin/rk32/rk322x_loader_*.bin
	elif [ "${CHIP}" == "rk3036" ]; then
		sudo $TOOLPATH/rkdeveloptool db ${LOCALPATH}/external/rkbin/rk30/rk3036_loader_*.bin
	elif [ "${CHIP}" == "rk3399" ]; then
		sudo $TOOLPATH/rkdeveloptool db ${LOCALPATH}/external/rkbin/rk33/rk3399_loader_*.bin
	elif [ "${CHIP}" == "rk3328" ]; then
		sudo $TOOLPATH/rkdeveloptool db ${LOCALPATH}/external/rkbin/rk33/rk3328_loader_*.bin
	fi

	sleep 1

	sudo $TOOLPATH/rkdeveloptool wl ${SEEK} ${IMAGE}

	sudo $TOOLPATH/rkdeveloptool rd
}

flash_sdcard() {
	pv -tpreb ${IMAGE} | sudo dd of=${DEVICE} seek=${SEEK} conv=notrunc
	sync
}

if [ ! $DEVICE ]; then
	flash_upgt
else
	flash_sdcard
fi
