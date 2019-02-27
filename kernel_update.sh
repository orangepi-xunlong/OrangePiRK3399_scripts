#!/bin/bash
set -e
##################################################
##
## Update kernel and DTS
##################################################
if [ -z $ROOT ]; then
	ROOT=`cd .. && pwd`
fi
KERNEL=$ROOT/output/boot.img
KERNEL_PATH="$1"
EXTLINUXPATH=$ROOT/external/extlinux
if [ ! -z $KERNEL_PATH ]; then
	cp $EXTLINUXPATH/rk3399_sd_boot.conf $EXTLINUXPATH/rk3399.conf
	./Generate_boot_image.sh 0
	./flash_tool.sh -c rk3399 -d $KERNEL_PATH -p boot -i $KERNEL
else
	cp $EXTLINUXPATH/rk3399_emmc_boot.conf $EXTLINUXPATH/rk3399.conf
	./Generate_boot_image.sh 1
	./flash_tool.sh -c rk3399 -p boot -i $KERNEL
fi

sync
clear
whiptail --title "OrangePi Build System" \
		 --msgbox "Succeed to update kernel" \
		  10 60
