#!/bin/sh

if [ -z $ROOT ]; then
	ROOT=`cd .. && pwd`
fi


BUILD=$ROOT/output
BOOT=$BUILD/boot.img
EXTLINUXPATH=$ROOT/external/extlinux
VAR=$1

if [ $VAR = "0" ]; then
	cp $EXTLINUXPATH/rk3399_sd_boot.conf $EXTLINUXPATH/rk3399.conf
elif [ $VAR = "1" ]; then
	cp $EXTLINUXPATH/rk3399_emmc_boot.conf $EXTLINUXPATH/rk3399.conf
else
	exit 0
fi
sync
rm -rf ${BOOT}
echo -e "\e[36m Generate Boot image start\e[0m"
#100 MB
mkfs.vfat -n "boot" -S 512 -C ${BOOT} $((100 * 1024))

mmd -i ${BOOT} ::/extlinux
mcopy -i ${BOOT} -s ${EXTLINUXPATH}/rk3399.conf ::/extlinux/extlinux.conf
mcopy -i ${BOOT} -s ${BUILD}/kernel/* ::
sync
echo -e "\e[36m Generate Boot image : ${BOOT} success! \e[0m"

