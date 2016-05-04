#!/bin/bash
set -e

# Fetch Sources
mkdir -p /usr/local/src
cd /usr/local/src

git clone --depth 1 https://github.com/l-smash/l-smash
git clone --depth 1 git://git.videolan.org/x264.git
hg clone https://bitbucket.org/multicoreware/x265
git clone --depth 1 git://github.com/mstorsjo/fdk-aac.git
git clone --depth 1 https://chromium.googlesource.com/webm/libvpx
git clone --depth 1 git://source.ffmpeg.org/ffmpeg
git clone https://git.xiph.org/opus.git
git clone --depth 1 https://github.com/mulx/aacgain.git
svn checkout http://svn.xvid.org/trunk --username anonymous --password "" xvid

# use all available processor cores for the build
alias make="make -j$(nproc)"

# Build libopus
cd /usr/local/src/opus
./autogen.sh
./configure --disable-shared
make 
make install

# Build L-SMASH
cd /usr/local/src/l-smash
./configure
make 
make install


# Build libfdk-aac
cd /usr/local/src/fdk-aac
autoreconf -fiv
./configure --disable-shared
make 
make install

# Build libvpx
cd /usr/local/src/libvpx
./configure --disable-examples --disable-unit-tests --disable-shared
make 
make install

# Build xvid
cd /usr/local/src/xvid/xvidcore/build/generic
./bootstrap.sh
./configure --disable-shared --enable-static
make
make install
rm -f /usr/local/lib/libxvidcore.4.dylib

# Build libx264
cd /usr/local/src/x264
./configure --enable-static
make 
make install

# Build libx265
cd /usr/local/src/x265/build/linux
sed -i '1s/^/#include <stdbool.h> /' /usr/local/src/x265/source/x265.h
cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="/usr/local" -DENABLE_SHARED:bool=off ../../source
make 
make install

# Build aacgain
cd /usr/local/src/aacgain/mp4v2
./configure && make -k || true # some commands fail but build succeeds
cd /usr/local/src/aacgain/faad2
./configure && make -k || true # some commands fail but build succeeds
cd /usr/local/src/aacgain
./configure && make && make install

# Build ffmpeg
cd /usr/local/src/ffmpeg
LD_RUN_PATH=/usr/local/lib PKG_CONFIG_PATH="/usr/local/lib/pkgconfig" ./configure --pkg-config-flags="--static" --extra-cflags="-I/usr/local/include" --extra-ldflags="-L/usr/local/lib" --extra-libs="-ldl" --enable-gpl --enable-version3 --enable-nonfree --enable-libass --enable-libfdk-aac --enable-libmp3lame --enable-libopus --enable-libtheora --enable-libvorbis --enable-libvpx --enable-libvpx --enable-libxvid --enable-libx264 --enable-libx265
make 
make install

# Remove all tmpfile
cd /
rm -rf /usr/local/src
