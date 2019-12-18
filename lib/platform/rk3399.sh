#!/bin/bash


install_gpu_lib()
{
	if [ $DISTRO = "bionic" ]; then
	cat > "$DEST/type-phase" <<EOF
#!/bin/bash

mkdir /tmp/libmali -p
dpkg -X /packages/libmali/libmali-rk-midgard-t86x-r14p0_1.6-2_arm64.deb /tmp/libmali
cp /tmp/libmali/usr/lib/aarch64-linux-gnu/lib* /usr/lib/aarch64-linux-gnu/ -rfa

sed 's/^#\(deb-src\)/\1/' -i /etc/apt/sources.list
apt update
apt-get -y build-dep xserver-xorg-core
cp -rfa /packages/xserver/xserver_for_bionic/* / 

apt-get clean
rm -rf /tmp/*
EOF
	elif [ $DISTRO = "xenial" -o $DISTRO = "stretch" ]; then
		cat > "$DEST/type-phase" <<EOF
#!/bin/bash -e

sed 's/^#\(deb-src\)/\1/' -i /etc/apt/sources.list
apt update
apt-get -y build-dep xserver-xorg-core
apt-get remove -y --purge libegl1-mesa-dev:arm64 libgbm-dev:arm64
dpkg -i /packages/libmali/*.deb
rm -rf /usr/lib/aarch64-linux-gnu/mesa-egl

apt-get -y install libxcb-xkb-dev libxfont-dev wayland-protocols

cp -rfa /packages/xserver/xserver_for_$DISTRO/* /

apt-get clean
EOF

fi
	chmod +x "$DEST/type-phase"
 	do_chroot /type-phase
	sync
	rm -f "$DEST/type-phase"
}


install_gstreamer()
{
	if [ $DISTRO = "bionic" ]; then 
#	cp /etc/resolv.conf "$DEST/etc/resolv.conf"
	cat > "$DEST/type-phase" << EOF
#!/bin/bash -e

apt-get install -y bison flex libffi-dev libmount-dev libpcre3 libpcre3-dev zlib1g-dev libssl-dev gtk-doc-tools \
        automake autoconf libtool  gettext make autopoint g++ xz-utils net-tools
apt-get install -y libasound2-dev libx11-dev


apt-get install -y unzip cmake make


apt-get -y install gstreamer1.0-plugins-* 
apt-get -y install gstreamer1.0-libav 
apt-get -y install libgstreamer1.0*
apt-get -y install libgstreamer1.0-dev 
apt-get -y install libgstreamer-plugins-base1.0-dev 
apt-get -y install libgstreamer-plugins-bad1.0-dev

cd /packages/source
unzip libdrm-rockchip-rockchip-2.4.74.zip
cd libdrm-rockchip-rockchip-2.4.74
./autogen.sh --prefix=/usr 
make
make install 
cd -

#git clone https://github.com/rockchip-linux/mpp.git
unzip mpp-release.zip
cd mpp-release/build/linux/aarch64
./make-Makefiles.bash
make
make install
cd -

#git clone https://github.com/rockchip-linux/gstreamer-rockchip.git
unzip gstreamer-rockchip.zip
cd gstreamer-rockchip-master
./autogen.sh --prefix=/usr --enable-gst --disable-rkximage
make 
make install
cd -


# git clone https://github.com/rockchip-linux/gstreamer-rockchip-extra.git
unzip gstreamer-rockchip-extra.zip
cd gstreamer-rockchip-extra-master
./autogen.sh --prefix=/usr --enable-gst --enable-rkximage
make
make install
cd -



# git clone https://github.com/rockchip-linux/camera_engine_rkisp.git
tar -xf camera_engine_rkisp.tar.xz
cd camera_engine_rkisp
mkdir -p build
make CROSS_COMPILE=

mkdir -p /etc/iqfiles
cp iqfiles/ov13850_CMK-CT0116_Largan-50013A1.xml /etc/iqfiles
mkdir -p /usr/lib/rkisp/ae
mkdir -p /usr/lib/rkisp/af
mkdir -p /usr/lib/rkisp/awb

cp ./build/lib/librkisp.so /usr/lib  -a
cp ./build/lib/libgstrkisp.so /usr/lib/gstreamer-1.0/ -a
cp ./build/ext/rkisp/usr/lib/gstreamer-1.0/libgstvideo4linux2.so /usr/lib/gstreamer-1.0/  -a
cp ./plugins/3a/rkiq/aec/lib64/librkisp_aec.so /usr/lib/rkisp/ae  -a
cp ./plugins/3a/rkiq/af/lib64/librkisp_af.so /usr/lib/rkisp/af -a
cp ./plugins/3a/rkiq/awb/lib64/librkisp_awb.so /usr/lib/rkisp/awb -a

cd -
#cp -rfa /usr/lib/gstreamer-1.0/* /usr/lib/aarch64-linux-gnu/gstreamer-1.0/
#cp /packages/test.mp4 /usr/local -f

cp /usr/lib/gstreamer-1.0/* /usr/lib/aarch64-linux-gnu/gstreamer-1.0/ -rfa
cp /packages/test.mp4 /usr/local/

apt-get clean
EOF
	elif [ $DISTRO = "xenial" -o $DISTRO = "stretch" ]; then
#		cp /etc/resolv.conf "$DEST/etc/resolv.conf"
	        cat > "$DEST/type-phase" << EOF

#!/bin/bash -e

apt-get install -y bison flex libffi-dev libmount-dev libpcre3 libpcre3-dev zlib1g-dev libssl-dev gtk-doc-tools \
        automake autoconf libtool  gettext make autopoint g++ xz-utils net-tools
apt-get install -y libasound2-dev libx11-dev
	
apt-get -y install unzip
apt-get -y install libxext-dev
apt-get -y install libjpeg62-dev
apt-get -y install gdisk

apt-get -y install libxv-dev libpulse-dev
apt-get -y install libgl1-mesa-dev libgles2-mesa

cp -rfa /packages/others/gstreamer/glib-2.52.3/* /
cp -rfa /packages/others/gstreamer/gstreamer-1.12.2/* /
cp -rfa /packages/others/gstreamer/gst-plugins-base-1.12.2/* /
cp -rfa /packages/others/gstreamer/gst-plugins-good-1.12.2/* /
cp -rfa /packages/others/gstreamer/gst-plugins-bad-1.12.2/* /
cp -rfa /packages/others/gstreamer/gst-plugins-ugly-1.12.2/* /
cp -rfa /packages/others/gstreamer/gst-libav-1.12.2/* /


cd /packages/source

# install orc
tar -xvf orc-0.4.25.tar
cd orc-0.4.25
./autogen.sh --prefix=/usr
make -j4
make install
cd -


# install  xorg-macros 1.12
# wget https://www.x.org/archive/individual/util/util-macros-1.12.0.tar.gz
tar -xvf util-macros-1.12.0.tar.gz
cd util-macros-1.12.0
./configure --prefix=/usr
make
make install
cd -
 
unzip libdrm-rockchip-rockchip-2.4.74.zip
cd libdrm-rockchip-rockchip-2.4.74
./autogen.sh --prefix=/usr

make -j4
make install
cd -


unzip mpp-release.zip
cd mpp-release/build/linux/aarch64/
./make-Makefiles.bash
make -j4
make install
cd -

# git clone https://github.com/rockchip-linux/gstreamer-rockchip.git
unzip gstreamer-rockchip.zip
cd gstreamer-rockchip-master
./autogen.sh --prefix=/usr --enable-gst --disable-rkximage
make -j4
make install
cd -

unzip gstreamer-rockchip-extra.zip
cd gstreamer-rockchip-extra-master
./autogen.sh --prefix=/usr --enable-gst --enable-rkximage
make -j4
make install
cd -



mkdir -p /etc/iqfiles
cp /packages/others/iqfiles/ov13850_CMK-CT0116_Largan-50013A1.xml /etc/iqfiles
mkdir -p /usr/lib/rkisp/ae
mkdir -p /usr/lib/rkisp/af
mkdir -p /usr/lib/rkisp/awb

# gstreamer Camera Support
cp /packages/others/rkisp/librkisp.so /usr/lib -a
cp /packages/others/rkisp/libgstvideo4linux2.so /usr/lib/ -a
cp /packages/others/rkisp/libgstrkisp.so /usr/lib/gstreamer-1.0 -a
# 3A lib
cp /packages/others/rkisp/librkisp_aec.so /usr/lib/rkisp/ae
cp /packages/others/rkisp/librkisp_af.so /usr/lib/rkisp/af
cp /packages/others/rkisp/librkisp_awb.so /usr/lib/rkisp/awb

cp /packages/test.mp4 /usr/local -f

apt-get clean
EOF

	fi
	chmod +x "$DEST/type-phase"
 	do_chroot /type-phase
	sync
	rm -f "$DEST/type-phase"

}
