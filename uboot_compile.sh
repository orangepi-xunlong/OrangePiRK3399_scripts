#!/bin/bash
set -e
#################################
##
## Compile U-boot
## This script will compile u-boot and merger with scripts.bin, bl31.bin and dtb.
#################################
# ROOT must be top direct.
if [ -z $ROOT ]; then
	ROOT=`cd .. && pwd`
fi
# PLATFORM.
if [ -z $PLATFORM ]; then
	PLATFORM="rk3399"
fi
# Uboot direct
UBOOT=$ROOT/uboot
# Compile Toolchain
TOOLS=$ROOT/toolchain/gcc-linaro-aarch/bin/aarch64-linux-gnu-
KERNEL=${ROOT}/kernel
#DTC_COMPILER=${KERNEL}/scripts/dtc/dtc

BUILD=$ROOT/output
CORES=$((`cat /proc/cpuinfo | grep processor | wc -l` - 1))
if [ $CORES -eq 0 ]; then
	CORES=1
fi

# Perpar souce code
if [ ! -d $UBOOT ]; then
	whiptail --title "OrangePi Build System" \
		--msgbox "u-boot doesn't exist, pls perpare u-boot source code." \
		10 50 0
	exit 0
fi
cd $ROOT
export CROSS_COMPILE=$TOOLS
./scripts/mk-uboot.sh rk3399-orangepi

cd -
echo -e "\e[1;31m =======================================\e[0m"
echo -e "\e[1;31m         Complete compile....		 \e[0m"
echo -e "\e[1;31m =======================================\e[0m"
echo " "
whiptail --title "OrangePi Build System" \
	--msgbox "Build uboot finish. The output path: $BUILD" 10 60 0
