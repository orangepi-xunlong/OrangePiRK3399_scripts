#!/bin/bash


install_rkgstreamer()
{
	if [ $DISTRO = "bionic" ]; then 
#	cp /etc/resolv.conf "$DEST/etc/resolv.conf"
	cat > "$DEST/type-phase" << EOF
#!/bin/bash -e

apt-get install -y bison flex libffi-dev libmount-dev libpcre3 libpcre3-dev zlib1g-dev libssl-dev gtk-doc-tools \
        automake autoconf libtool  gettext make autopoint g++ xz-utils
apt-get install -y libasound2-dev libx11-dev


apt-get install -y unzip cmake make


apt-get -y install gstreamer1.0-plugins-* 
apt-get -y install gstreamer1.0-libav 
apt-get -y install libgstreamer1.0*
apt-get -y install libgstreamer1.0-dev 
apt-get -y install libgstreamer-plugins-base1.0-dev 
apt-get -y install libgstreamer-plugins-bad1.0-dev

cd /packages/zip
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
unzip camera_engine_rkisp.zip
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
apt-get install -y bison flex libffi-dev libmount-dev \
		libpcre3 libpcre3-dev zlib1g-dev libssl-dev \
			gtk-doc-tools automake autoconf \
				libtool gettext make autopoint g++ xz-utils
	
apt-get -y install libasound2-dev libx11-dev unzip
apt-get -y install libxext-dev

cd /packages/zip
# install glib	
tar xvf glib-2.52.3.tar
cd glib-2.52.3
./autogen.sh 
make -j12
make install
cd -


# install orc
tar -xvf orc-0.4.25.tar
cd orc-0.4.25
./autogen.sh --prefix=/usr
make -j12 
make install
cd -

# install gstreamer-1.12.2
tar -xvf gstreamer-1.12.2.tar.xz
cd gstreamer-1.12.2
./autogen.sh --prefix=/usr  --disable-gtk-doc
make -j12
make install
cd -

# install gst-plugins-base-1.12.2
tar -xvf gst-plugins-base-1.12.2.tar.xz
cd gst-plugins-base-1.12.2
./autogen.sh --prefix=/usr --disable-gtk-doc
make -j12
make install
cd -

# install gst-plugins-good-1.12.2
tar -xvf gst-plugins-good-1.12.2.tar.xz
cd gst-plugins-good-1.12.2
./autogen.sh --prefix=/usr --disable-gtk-doc
make -j12
make install
cd -

apt-get -y install libgl1-mesa-dev libgles2-mesa
# install gst-plugins-bad-1.12.2
tar -xvf gst-plugins-bad-1.12.2.tar.xz
cd gst-plugins-bad-1.12.2
./autogen.sh --prefix=/usr --disable-gtk-doc
make -j12
make install
cd -

# install gst-plugins-ugly-1.12.2
tar -xvf gst-plugins-ugly-1.12.2.tar.xz
cd gst-plugins-ugly-1.12.2
./autogen.sh --prefix=/usr --disable-gtk-doc
make -j12
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

make -j12
make install
cd -


unzip mpp-release.zip
cd mpp-release/build/linux/aarch64/
./make-Makefiles.bash
make -j12
make install
cd -

# git clone https://github.com/rockchip-linux/gstreamer-rockchip.git
unzip gstreamer-rockchip.zip
cd gstreamer-rockchip-master
./autogen.sh --prefix=/usr --enable-gst --disable-rkximage
make -j12
make install
cd -

unzip gstreamer-rockchip-extra.zip
cd gstreamer-rockchip-extra-master
./autogen.sh --prefix=/usr --enable-gst --enable-rkximage
make -j12
make install
cd -



mkdir -p /etc/iqfiles
cp /packages/iqfiles/ov13850_CMK-CT0116_Largan-50013A1.xml /etc/iqfiles
mkdir -p /usr/lib/rkisp/ae
mkdir -p /usr/lib/rkisp/af
mkdir -p /usr/lib/rkisp/awb

# gstreamer Camera Support
cp /packages/lib/librkisp.so /usr/lib -a
cp /packages/lib/libgstvideo4linux2.so /usr/lib/ -a
cp /packages/lib/libgstrkisp.so /usr/lib/gstreamer-1.0 -a
# 3A lib
cp /packages/lib/librkisp_aec.so /usr/lib/rkisp/ae
cp /packages/lib/librkisp_af.so /usr/lib/rkisp/af
cp /packages/lib/librkisp_awb.so /usr/lib/rkisp/awb

cp /packages/test.mp4 /usr/local -f

EOF

	fi
	chmod +x "$DEST/type-phase"
 	do_chroot /type-phase
	sync
	rm -f "$DEST/type-phase"

}
