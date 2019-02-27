#!/bin/bash
set -e
#########################################################
##
##
## Update uboot and boot0
#########################################################
# ROOT must be top direct
if [ -z $ROOT ]; then
	ROOT=`cd .. && pwd`
fi
# Output path, must /dev/sdx
OUTPUT="$1"

LOADER1=$ROOT/output/u-boot/idbloader.img
echo $LOADER1
UBOOT=$ROOT/output/u-boot/uboot.img
ATF=$ROOT/output/u-boot/trust.img

if [ ! -z $OUTPUT ]; then
	# Update loader1
	./flash_tool.sh -d ${OUTPUT} -p loader1 -i ${LOADER1} -c rk3399

	# Update loader2.
	./flash_tool.sh -d ${OUTPUT} -p loader2 -i ${UBOOT} -c rk3399
	
	# Update atf
	./flash_tool.sh -d ${OUTPUT} -p atf -i ${ATF} -c rk3399
else
	./flash_tool.sh   -p loader2 -i ${UBOOT} -c rk3399
fi

sync
clear
whiptail --title "OrangePi Build System" --msgbox "Succeed to update Uboot" 10 40 0
