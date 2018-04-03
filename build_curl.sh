#!/usr/bin/env bash
#set -x 
function extract() {
    if [ -f "$1" ] ; then
         case "$1" in
             *.tar.bz2)   tar xvjf "$1"     ;;
             *.tar.gz)    tar xvzf "$1"     ;;
             *.tar.xz)    tar xvf "$1"     ;;
             *.bz2)       bunzip2 "$1"      ;;
             *.rar)       unrar x "$1"      ;;
             *.gz)        gunzip "$1"       ;;
             *.tar)       tar xvf "$1"      ;;
             *.tbz2)      tar xvjf "$1"     ;;
             *.tgz)       tar xvzf "$1"     ;;
             *.zip)       unzip "$1"        ;;
             *.Z)         uncompress "$1"   ;;
             *.7z)        7z x "$1"         ;;
             *)           echo "$1 cannot be extracted via >extract<" ;;
         esac
    else
         echo "'$1' is not a valid file"
    fi
}

# for CentOS, install libgcrypt-devel.x86_64 libmount-devel


##############
## Configs
##############

echo "* Variable Configurations"

ZLIB_VERSION="1.2.11"
ZLIB_EXTENSION=".tar.gz"
ZLIB_DIRECTORY="zlib-${ZLIB_VERSION}"
ZLIB_TARBALL="zlib-${ZLIB_VERSION}${ZLIB_EXTENSION}"

OPENSSL_VERSION="1.0.2o"
OPENSSL_EXTENSION=".tar.gz"
OPENSSL_DIRECTORY="openssl-${OPENSSL_VERSION}"
OPENSSL_TARBALL="openssl-${OPENSSL_VERSION}${OPENSSL_EXTENSION}"

CURL_VERSION="7.59.0"
CURL_EXTENSION=".tar.gz"
CURL_DIRECTORY="curl-${CURL_VERSION}"
CURL_TARBALL="curl-${CURL_VERSION}${OPENSSL_EXTENSION}"

##############
## Download
##############

echo "* Download files"

# Only download zlib tarball again if not already downloaded
if [[ ! -f "${ZLIB_TARBALL}" ]]; then
  wget -v -nc "http://zlib.net/${ZLIB_TARBALL}"
fi
if [[ ! -d "${ZLIB_DIRECTORY}" ]]; then
  extract "$ZLIB_TARBALL"
fi
if [[ ! -d "${ZLIB_DIRECTORY}" ]]; then 
  echo "Problem with extracting zlib from $ZLIB_TARBALL into $ZLIB_DIRECTORY!!!" 
  exit -1 
fi

# Only download openssl tarball again if not already downloaded
if [[ ! -f "${OPENSSL_TARBALL}" ]]; then
  wget -v -nc "https://www.openssl.org/source/${OPENSSL_TARBALL}"
fi
if [[ ! -d "${OPENSSL_DIRECTORY}" ]]; then
  extract "$OPENSSL_TARBALL"
fi
if [[ ! -d "${OPENSSL_DIRECTORY}" ]]; then 
  echo "Problem with extracting openssl from $OPENSSL_TARBALL into $OPENSSL_DIRECTORY!!!" 
  exit -1 
fi

# Only download openssl tarball again if not already downloaded
if [[ ! -f "${CURL_TARBALL}" ]]; then
  wget -v -nc "https://curl.haxx.se/download/${CURL_TARBALL}"
fi
if [[ ! -d "${CURL_DIRECTORY}" ]]; then
  extract "$CURL_TARBALL"
fi
if [[ ! -d "${CURL_DIRECTORY}" ]]; then 
  echo "Problem with extracting curl from $CURL_TARBALL into $CURL_DIRECTORY!!!" 
  exit -1 
fi

##############
## Setup Env
##############

echo "* Setup TOOLCHAIN"

BUILD_SYS=x86_64-linux-gnu

# Setup Android NDk path
if [[ ! -n $ANDROID_NDK_HOME ]]; then
  export ANDROID_NDK_HOME="/mnt/Lucifer/yanzi/Android/android-ndk-r11c"
fi

# Setup Android lib path (temporary)
if [[ ! -d ${HOME}/.android_lib/ ]]; then
  mkdir ${HOME}/.android_lib/
fi
export PREFIX="${HOME}/.android_lib"

# Don't mix up .pc files from your host and build target
export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig

# Build target
ARCH_ABI="arm-linux-androideabi-4.9"
ANDROID_PLATFORM=android-21

# setup NDK standalone toolchain
if [[ ! -n $NDK_TOOLCHAIN ]]; then
  export NDK_TOOLCHAIN="/mnt/Lucifer/yanzi/Android/lib/${ANDROID_PLATFORM}-toolchain-r11c"
fi

if [[ ! -d "$NDK_TOOLCHAIN" ]]; then 
  echo "$NDK_TOOLCHAIN does not exist!!!" 
  exit -1 
fi


# ARM Toolchain 
# CROSS_PREFIX=$ANDROID_NDK_HOME/toolchains/${ARCH_ABI}/prebuilt/linux-x86_64/bin
CROSS_PREFIX=${NDK_TOOLCHAIN}/bin
# export AR="${CROSS_PREFIX}/arm-linux-androideabi-ar"
# export LD="${CROSS_PREFIX}/arm-linux-androideabi-ld" 
# export CC="${CROSS_PREFIX}/arm-linux-androideabi-gcc" 
# export CXX="${CROSS_PREFIX}/arm-linux-androideabi-g++" 
export AR=${CROSS_PREFIX}/arm-linux-androideabi-ar
export AS=${CROSS_PREFIX}/arm-linux-androideabi-as
export LD=${CROSS_PREFIX}/arm-linux-androideabi-ld
export NM=${CROSS_PREFIX}/arm-linux-androideabi-nm
export CC=${CROSS_PREFIX}/arm-linux-androideabi-gcc-4.9
export CXX=${CROSS_PREFIX}/arm-linux-androideabi-g++
export CPP=${CROSS_PREFIX}/arm-linux-androideabi-cpp
export CXXCPP=${CROSS_PREFIX}/arm-linux-androideabi-cpp
export STRIP=${CROSS_PREFIX}/arm-linux-androideabi-strip
export RANLIB=${CROSS_PREFIX}/arm-linux-androideabi-ranlib
export STRINGS=${CROSS_PREFIX}/arm-linux-androideabi-strings

[[ ! -d "$ANDROID_NDK_HOME" || ! -f "$AR" || ! -f "$LD" || ! -f "$CC" || ! -f "$CXX" ]] && echo "Make sure AR, LD, CC, CXX variables are defined correctly. Ensure ANDROID_NDK_HOME is defined also" && exit -1 

# Configure build
# SYSROOT=$ANDROID_NDK_HOME/platforms/${ANDROID_PLATFORM}/arch-arm
SYSROOT=${NDK_TOOLCHAIN}/sysroot
export CPPFLAGS="--sysroot=${SYSROOT} -I${SYSROOT}/usr/include -I${NDK_TOOLCHAIN}/include/c++/ -fPIE -DANDROID -DNO_XMALLOC -mandroid" 
export CFLAGS="--sysroot=${SYSROOT} -I${SYSROOT}/usr/include -I${PREFIX}/include -fPIE -DANDROID -Wno-multichar"
export CXXFLAGS="${CFLAGS}"
export LIBS="-lc"
export LDFLAGS="-Wl,-rpath-link=-I${SYSROOT}/usr/lib -L${SYSROOT}/usr/lib -L${PREFIX}/lib -L${NDK_TOOLCHAIN}/lib -fPIE"

# Needed for openssh building
export HOSTCC="/usr/local/bin/gcc"
export PATH=$PATH:${PREFIX}/bin:${PREFIX}/lib
export INSTALLATION_PATH=${PREFIX}

_ANDROID_ARCH="arch-arm"
export ARCH="arm"
export SYSTEM="android"
export MACHINE="armv7"
_ANDROID_EABI=$ARCH_ABI
ANDROID_NDK_ROOT=$NDK_TOOLCHAIN
ANDROID_API=$ANDROID_PLATFORM
ANDROID_SYSROOT=$SYSROOT
ANDROID_TOOLCHAIN=$CROSS_PREFIX
CROSS_COMPILE="arm-linux-androideabi-"

export ANDROID_DEV="${SYSROOT}/usr"

VERBOSE=1
if [ ! -z "$VERBOSE" ] && [ "$VERBOSE" != "0" ]; then
  echo "ANDROID_NDK_ROOT: $NDK_TOOLCHAIN"
  echo "ANDROID_ARCH: $_ANDROID_ARCH"
  echo "ANDROID_EABI: $_ANDROID_EABI"
  echo "ANDROID_API: $ANDROID_API"
  echo "ANDROID_SYSROOT: $ANDROID_SYSROOT"
  echo "ANDROID_TOOLCHAIN: $ANDROID_TOOLCHAIN"
  echo "CROSS_COMPILE: $CROSS_COMPILE"
  echo "ANDROID_DEV: $ANDROID_DEV"
fi

##############
## Build Start
##############


# build zlib for Android
echo "* building zlib"

cd "$ZLIB_DIRECTORY"
./configure \
  --prefix=${PREFIX} \
  --static
make -j4
make install
cd ..

export LDFLAGS="${LDFLAGS} -pie"

# build openssl for Android
echo "* building openssl"
cd "$OPENSSL_DIRECTORY"
sed -i.bak 's/install: all install_docs install_sw/install: install_docs install_sw/g' Makefile.org
./config shared no-ssl2 no-ssl3 no-comp no-hw no-engine \
  --openssldir=$INSTALLATION_PATH
make depend
make all
make install


# build curl for Android
export LIBS="$LIBS -lssl -lcrypto"
echo "* building curl"
cd "$CURL_DIRECTORY"
./configure \
  --host=arm-linux-androideabi \
  --with-ssl \
  --with-zlib \
  --disable-ftp \
  --disable-gopher \
  --disable-file \
  --disable-imap \
  --disable-ldap \
  --disable-ldaps \
  --disable-pop3 \
  --disable-proxy \
  --disable-rtsp \
  --disable-smtp \
  --disable-telnet \
  --disable-tftp \
  --without-gnutls \
  --without-libidn \
  --without-librtmp \
  --disable-dict \
  --enable-static \
  --prefix=${PREFIX}
make -j4
make install

