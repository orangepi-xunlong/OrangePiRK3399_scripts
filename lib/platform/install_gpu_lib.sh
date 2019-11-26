#!/bin/bash

install_rkgpu()
{
	if [ $DISTRO = "bionic" ]; then
#		cp /etc/resolv.conf "$DEST/etc/resolv.conf"
		cat > "$DEST/type-phase" <<EOF
#!/bin/bash

mkdir /tmp/libmali -p
apt-get -y install net-tools
dpkg -X /packages/deb/libmali/libmali-rk-midgard-t86x-r14p0_1.6-2_arm64.deb /tmp/libmali
cp /tmp/libmali/usr/lib/aarch64-linux-gnu/lib* /usr/lib/aarch64-linux-gnu/ -rfa

mkdir /tmp/xserver -p
apt-get -y build-dep xserver-xorg-core
dpkg -X /packages/deb/xserver/xserver_2019-11-18-1_arm64.deb /tmp/xserver
cp /tmp/xserver/* / -rfa

apt-get clean

EOF
	elif [ $DISTRO = "xenial" -o $DISTRO = "stretch" ]; then
#		cp /etc/resolv.conf "$DEST/etc/resolv.conf"
		cat > "$DEST/type-phase" <<EOF
#!/bin/bash

apt-get -y build-dep xserver-xorg-core
apt-get remove -y --purge libegl1-mesa-dev:arm64 libgbm-dev:arm64
dpkg -i /packages/deb/libmali/libmali-rk-dev_1.6-2_arm64.deb
dpkg -i /packages/deb/libmali/libmali-rk-midgard-t86x-r14p0_1.6-2_arm64.deb
apt-get install -y libxcb-xkb-dev libxfont-dev wayland-protocols
apt-get remove -y --purge xserver-xorg-core xserver-common
dpkg -i /packages/deb/xserver/xserver_2019-11-13-1_arm64.deb
apt-get install -y libevdev-dev libmtdev-dev
dpkg -i /packages/deb/xserver/xserver-xorg-input-evdev_2019-11-13-1_arm64.deb

EOF
	fi
	chmod +x "$DEST/type-phase"
 	do_chroot /type-phase
	sync
	rm -f "$DEST/type-phase"
}


