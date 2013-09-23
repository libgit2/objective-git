#!/bin/bash

# Yay shell scripting! This script builds a static version of
# OpenSSL ${OPENSSL_VERSION} for iOS 5.1 that contains code for armv6, armv7 and i386.

set -x

if [ -f "External/ios-openssl/lib/libssl.a" ] && [ -f "External/ios-openssl/lib/libcrypto.a" ] && [ -d "External/ios-openssl/include" ]
then
    echo "No update needed."
    exit 0
fi

# Setup paths to stuff we need

DEVELOPER="/Applications/Xcode.app/Contents/Developer"

SDK_VERSION="7.0"

CLANG=`/usr/bin/xcrun --find clang`

IPHONEOS_PLATFORM="${DEVELOPER}/Platforms/iPhoneOS.platform"
IPHONEOS_SDK="${IPHONEOS_PLATFORM}/Developer/SDKs/iPhoneOS${SDK_VERSION}.sdk"

IPHONESIMULATOR_PLATFORM="${DEVELOPER}/Platforms/iPhoneSimulator.platform"
IPHONESIMULATOR_SDK="${IPHONESIMULATOR_PLATFORM}/Developer/SDKs/iPhoneSimulator${SDK_VERSION}.sdk"

# Clean up whatever was left from our previous build

rm -rf External/ios-openssl/include External/ios-openssl/lib
rm -rf "/tmp/openssl"
rm -rf "/tmp/openssl-*.log"

build()
{
   ARCH=$1
   SDK=$2
   rm -rf "/tmp/openssl"
   cp -r External/openssl /tmp/
   pushd .
   cd "/tmp/openssl"
   ./Configure BSD-generic32 no-gost --openssldir="/tmp/openssl-${ARCH}" &> "/tmp/openssl-${ARCH}.log"
   perl -i -pe 's|static volatile sig_atomic_t intr_signal|static volatile int intr_signal|' crypto/ui/ui_openssl.c
   perl -i -pe "s|^CC= gcc|CC= ${CLANG} -arch ${ARCH}|g" Makefile
   perl -i -pe "s|^CFLAG= (.*)|CFLAG= -isysroot ${SDK} \$1|g" Makefile
   make &> "/tmp/openssl-${ARCH}.log"
   make install &> "/tmp/openssl-${ARCH}.log"
   popd
   rm -rf "/tmp/openssl"
}

build "armv7" "${IPHONEOS_SDK}"
build "armv7s" "${IPHONEOS_SDK}"
build "i386" "${IPHONESIMULATOR_SDK}"

#

mkdir External/ios-openssl/include
cp -r /tmp/openssl-i386/include/openssl External/ios-openssl/include/

mkdir External/ios-openssl/lib
lipo \
	"/tmp/openssl-armv7/lib/libcrypto.a" \
	"/tmp/openssl-armv7s/lib/libcrypto.a" \
	"/tmp/openssl-i386/lib/libcrypto.a" \
	-create -output External/ios-openssl/lib/libcrypto.a
lipo \
	"/tmp/openssl-armv7/lib/libssl.a" \
	"/tmp/openssl-armv7s/lib/libssl.a" \
	"/tmp/openssl-i386/lib/libssl.a" \
	-create -output External/ios-openssl/lib/libssl.a

rm -rf "/tmp/openssl"
rm -rf "/tmp/openssl-*.log"

