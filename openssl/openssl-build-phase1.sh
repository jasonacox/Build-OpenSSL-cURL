#!/bin/bash
#
# This script downlaods and builds the Mac, Mac Catalyst and tvOS openSSL libraries with Bitcode enabled
#
# Author: Jason Cox, @jasonacox https://github.com/jasonacox/Build-OpenSSL-cURL
# Date: 2020-Aug-15
#

set -e

# Custom build options
CUSTOMCONFIG="enable-ssl-trace"

# Formatting
default="\033[39m"
wihte="\033[97m"
green="\033[32m"
red="\033[91m"
yellow="\033[33m"

bold="\033[0m${green}\033[1m"
subbold="\033[0m${green}"
archbold="\033[0m${yellow}\033[1m"
normal="${white}\033[0m"
dim="\033[0m${white}\033[2m"
alert="\033[0m${red}\033[1m"
alertdim="\033[0m${red}\033[2m"

# Set trap to help debug build errors
trap 'echo -e "${alert}** ERROR with Build - Check /tmp/openssl*.log${alertdim}"; tail -3 /tmp/openssl*.log' INT TERM EXIT

# Set defaults
VERSION="3.0.9"				# OpenSSL version default
catalyst="0"

# Set minimum OS versions for target
MACOS_X86_64_VERSION=""			# Empty = use host version
MACOS_ARM64_VERSION=""			# Min supported is MacOS 11.0 Big Sur
CATALYST_IOS="15.0"				# Min supported is iOS 15.0 for Mac Catalyst
IOS_MIN_SDK_VERSION="8.0"
IOS_SDK_VERSION=""
TVOS_MIN_SDK_VERSION="9.0"
TVOS_SDK_VERSION=""

CORES=$(sysctl -n hw.ncpu)
OPENSSL_VERSION="openssl-${VERSION}"

if [ -z "${MACOS_X86_64_VERSION}" ]; then
	MACOS_X86_64_VERSION=$(sw_vers -productVersion)
fi
if [ -z "${MACOS_ARM64_VERSION}" ]; then
	MACOS_ARM64_VERSION=$(sw_vers -productVersion)
fi

usage ()
{
	echo
	echo -e "${bold}Usage:${normal}"
	echo
	echo -e "  ${subbold}$0${normal} [-v ${dim}<version>${normal}] [-s ${dim}<version>${normal}] [-t ${dim}<version>${normal}] [-i ${dim}<version>${normal}] [-a ${dim}<version>${normal}] [-u ${dim}<version>${normal}] [-e] [-m] [-3] [-x] [-h]"
	echo
	echo "         -v   version of OpenSSL (default $VERSION)"
	echo "         -s   iOS min target version (default $IOS_MIN_SDK_VERSION)"
	echo "         -t   tvOS min target version (default $TVOS_MIN_SDK_VERSION)"
	echo "         -i   macOS 86_64 min target version (default $MACOS_X86_64_VERSION)"
	echo "         -a   macOS arm64 min target version (default $MACOS_ARM64_VERSION)"
	echo "         -e   compile with engine support"
	echo "         -m   compile Mac Catalyst library"
	echo "         -u   Mac Catalyst iOS min target version (default $CATALYST_IOS)"
	echo "         -3   compile with SSLv3 support"
	echo "         -x   disable color output"
	echo "         -h   show usage"
	echo
	trap - INT TERM EXIT
	exit 127
}

engine=0

while getopts "v:s:t:i:a:u:emx3h\?" o; do
	case "${o}" in
		v)
			OPENSSL_VERSION="openssl-${OPTARG}"
			;;
		s)
			IOS_MIN_SDK_VERSION="${OPTARG}"
			;;
		t)
			TVOS_MIN_SDK_VERSION="${OPTARG}"
			;;
		i)
			MACOS_X86_64_VERSION="${OPTARG}"
			;;
		a)
			MACOS_ARM64_VERSION="${OPTARG}"
			;;
		e)
			engine=1
			;;
		m)
			catalyst="1"
			;;
		u)
			catalyst="1"
			CATALYST_IOS="${OPTARG}"
			;;
		x)
			bold=""
			subbold=""
			normal=""
			dim=""
			alert=""
			alertdim=""
			archbold=""
			;;
		3)
			CUSTOMCONFIG="enable-ssl3 enable-ssl3-method enable-ssl-trace"
			;;
		*)
			usage
			;;
	esac
done
shift $((OPTIND-1))

DEVELOPER=`xcode-select -print-path`

# Semantic Version Comparison
version_lte() {
    [  "$1" = "`echo -e "$1\n$2" | sort -V | head -n1`" ]
}
if version_lte $MACOS_ARM64_VERSION 11.0; then
        MACOS_ARM64_VERSION="11.0"      # Min support for Apple Silicon is 11.0
fi

buildMac()
{
	ARCH=$1

	TARGET="darwin-i386-cc"
	BUILD_MACHINE=`uname -m`

	if [[ $ARCH == "x86_64" ]]; then
		TARGET="darwin64-x86_64-cc"
		MACOS_VER="${MACOS_X86_64_VERSION}"
		if [ ${BUILD_MACHINE} == 'arm64' ]; then
   			# Apple ARM Silicon Build Machine Detected - cross compile
			export CC="clang"
			export CXX="clang"
			export CFLAGS=" -Os -mmacosx-version-min=${MACOS_X86_64_VERSION} -arch ${ARCH} "
			export LDFLAGS=" -arch ${ARCH} -isysroot ${DEVELOPER}/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk "
			export CPPFLAGS=" -I.. -isysroot ${DEVELOPER}/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk "
		else
			# Apple x86_64 Build Machine Detected - native build
			export CFLAGS=" -Os -mmacosx-version-min=${MACOS_X86_64_VERSION} -arch ${ARCH} "
		fi
	fi
	if [[ $ARCH == "arm64" ]]; then
		TARGET="darwin64-arm64-cc"
		MACOS_VER="${MACOS_ARM64_VERSION}"
		if [ ${BUILD_MACHINE} == 'arm64' ]; then
   			# Apple ARM Silicon Build Machine Detected - native build
			export CC="${BUILD_TOOLS}/usr/bin/gcc"
			export CFLAGS=" -Os -mmacosx-version-min=${MACOS_ARM64_VERSION} -arch ${ARCH} "
		else
			# Apple x86_64 Build Machine Detected - cross compile
			export CC="clang"
			export CXX="clang"
			export CFLAGS=" -Os -mmacosx-version-min=${MACOS_ARM64_VERSION} -arch ${ARCH} "
			export LDFLAGS=" -arch ${ARCH} -isysroot ${DEVELOPER}/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk "
			export CPPFLAGS=" -I.. -isysroot ${DEVELOPER}/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk "
		fi
	fi

	echo -e "${subbold}Building ${OPENSSL_VERSION} for ${archbold}${ARCH}${dim} (MacOS ${MACOS_VER})"

	pushd . > /dev/null
	cd "${OPENSSL_VERSION}"
	if [[ "$OPENSSL_VERSION" = "openssl-1.0"* ]]; then
		./Configure no-asm ${TARGET} -no-shared  --openssldir="/tmp/${OPENSSL_VERSION}-${ARCH}" $CUSTOMCONFIG &> "/tmp/${OPENSSL_VERSION}-${ARCH}.log"
	else
		./Configure no-asm ${TARGET} -no-shared  --prefix="/tmp/${OPENSSL_VERSION}-${ARCH}" --openssldir="/tmp/${OPENSSL_VERSION}-${ARCH}" $CUSTOMCONFIG &> "/tmp/${OPENSSL_VERSION}-${ARCH}.log"
	fi
	make -j${CORES} >> "/tmp/${OPENSSL_VERSION}-${ARCH}.log" 2>&1
	make install_sw >> "/tmp/${OPENSSL_VERSION}-${ARCH}.log" 2>&1
	# Keep openssl binary for Mac version
	cp "/tmp/${OPENSSL_VERSION}-${ARCH}/bin/openssl" "/tmp/openssl-${ARCH}"
	cp "/tmp/${OPENSSL_VERSION}-${ARCH}/bin/openssl" "/tmp/openssl"
	make clean >> "/tmp/${OPENSSL_VERSION}-${ARCH}.log" 2>&1
	popd > /dev/null

	if [ $ARCH == ${BUILD_MACHINE} ]; then
		echo -e "Testing binary for ${BUILD_MACHINE}:"
		/tmp/openssl version
	fi

	# Clean up exports
	export CC=""
	export CXX=""
	export CFLAGS=""
	export LDFLAGS=""
	export CPPFLAGS=""
}

buildCatalyst()
{
	ARCH=$1

	# disabe bitcode for openssl 3
	if [[ "$OPENSSL_VERSION" = "openssl-3.0"* ]]; then
		CC_BITCODE_FLAG=""
	else
		CC_BITCODE_FLAG="-fembed-bitcode"
	fi

	pushd . > /dev/null
	cd "${OPENSSL_VERSION}"

	TARGET="darwin64-${ARCH}-cc"
	BUILD_MACHINE=`uname -m`
	export PLATFORM="MacOSX"
	export CROSS_TOP="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
	export CROSS_SDK="${PLATFORM}.sdk"
	export BUILD_TOOLS="${DEVELOPER}"
	export CC="${BUILD_TOOLS}/usr/bin/gcc ${CC_BITCODE_FLAG} -arch ${ARCH} -target ${ARCH}-apple-ios${CATALYST_IOS}-macabi"

	if [[ $ARCH == "x86_64" ]]; then
		TARGET="darwin64-x86_64-cc"
		MACOS_VER="${MACOS_X86_64_VERSION}"
		if [ ${BUILD_MACHINE} == 'arm64' ]; then
   			# Apple ARM Silicon Build Machine Detected - cross compile
			export CC="clang"
			export CXX="clang"
			export CFLAGS=" -Os -mmacosx-version-min=${MACOS_X86_64_VERSION} -arch ${ARCH} ${CC_BITCODE_FLAG} -target ${ARCH}-apple-ios${CATALYST_IOS}-macabi "
			export LDFLAGS=" -arch ${ARCH} -isysroot ${DEVELOPER}/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk "
			export CPPFLAGS=" -I.. -isysroot ${DEVELOPER}/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk "
		else
			# Apple x86_64 Build Machine Detected - native build
			export CFLAGS=" -Os -mmacosx-version-min=${MACOS_X86_64_VERSION} -arch ${ARCH} ${CC_BITCODE_FLAG} -target ${ARCH}-apple-ios${CATALYST_IOS}-macabi "
		fi
	fi
	if [[ $ARCH == "arm64" ]]; then
		TARGET="darwin64-arm64-cc"
		MACOS_VER="${MACOS_ARM64_VERSION}"
		if [ ${BUILD_MACHINE} == 'arm64' ]; then
   			# Apple ARM Silicon Build Machine Detected - native build
			export CC="${BUILD_TOOLS}/usr/bin/gcc"
			export CFLAGS=" -Os -mmacosx-version-min=${MACOS_ARM64_VERSION} -arch ${ARCH} ${CC_BITCODE_FLAG} -target ${ARCH}-apple-ios${CATALYST_IOS}-macabi "
		else
			# Apple x86_64 Build Machine Detected - cross compile
			export CFLAGS=" -Os -mmacosx-version-min=${MACOS_ARM64_VERSION} -arch ${ARCH} ${CC_BITCODE_FLAG} -target ${ARCH}-apple-ios${CATALYST_IOS}-macabi "
			export LDFLAGS=" -arch ${ARCH} -isysroot ${DEVELOPER}/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk "
			export CPPFLAGS=" -I.. -isysroot ${DEVELOPER}/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk "
		fi
	fi

	echo -e "${subbold}Building ${OPENSSL_VERSION} for ${archbold}${ARCH}${dim} (MacOS ${MACOS_VER} Catalyst iOS ${CATALYST_IOS})"

	if [[ "$OPENSSL_VERSION" = "openssl-1.0"* ]]; then
		./Configure no-asm ${TARGET} -no-shared  --openssldir="/tmp/${OPENSSL_VERSION}-catalyst-${ARCH}" $CUSTOMCONFIG &> "/tmp/${OPENSSL_VERSION}-catalyst-${ARCH}.log"
	else
		./Configure no-asm ${TARGET} -no-shared  --prefix="/tmp/${OPENSSL_VERSION}-catalyst-${ARCH}" --openssldir="/tmp/${OPENSSL_VERSION}-catalyst-${ARCH}" $CUSTOMCONFIG &> "/tmp/${OPENSSL_VERSION}-catalyst-${ARCH}.log"
	fi

	#if [[ "$OPENSSL_VERSION" = "openssl-1.1.1"* ]]; then
	#	sed -ie "s!^CFLAGS=!CFLAGS=-isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} !" "Makefile"
	#else
	#	sed -ie "s!^CFLAG=!CFLAG=-isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} !" "Makefile"
	#fi

	make -j${CORES} >> "/tmp/${OPENSSL_VERSION}-catalyst-${ARCH}.log" 2>&1
	make install_sw >> "/tmp/${OPENSSL_VERSION}-catalyst-${ARCH}.log" 2>&1
	make clean >> "/tmp/${OPENSSL_VERSION}-catalyst-${ARCH}.log" 2>&1
	popd > /dev/null

	# Clean up exports
	export CC=""
	export CXX=""
	export CFLAGS=""
	export LDFLAGS=""
	export CPPFLAGS=""
}

buildTVOS()
{
	ARCH=$1

	pushd . > /dev/null
	cd "${OPENSSL_VERSION}"

	if [[ "${ARCH}" == "x86_64" ]]; then
		PLATFORM="AppleTVSimulator"
	else
		PLATFORM="AppleTVOS"
		sed -ie "s!static volatile sig_atomic_t intr_signal;!static volatile intr_signal;!" "crypto/ui/ui_openssl.c"
	fi

	export $PLATFORM
	export CROSS_TOP="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
	export CROSS_SDK="${PLATFORM}${TVOS_SDK_VERSION}.sdk"
	export BUILD_TOOLS="${DEVELOPER}"
	export CC="${BUILD_TOOLS}/usr/bin/gcc -fembed-bitcode -arch ${ARCH}"
	export LC_CTYPE=C

	echo -e "${subbold}Building ${OPENSSL_VERSION} for ${PLATFORM} ${TVOS_SDK_VERSION} ${archbold}${ARCH}${dim} (tvOS ${TVOS_MIN_SDK_VERSION})"

	# Patch apps/speed.c to not use fork() since it's not available on tvOS
	LANG=C sed -i -- 's/define HAVE_FORK 1/define HAVE_FORK 0/' "./apps/speed.c"
	if [[ "$OPENSSL_VERSION" = "openssl-1.1.1"* ]]; then
		LANG=C sed -i -- 's/!defined(OPENSSL_NO_POSIX_IO)/defined(HAVE_FORK)/' "./apps/ocsp.c"
		LANG=C sed -i -- 's/fork()/-1/' "./apps/ocsp.c"
		LANG=C sed -i -- 's/fork()/-1/' "./test/drbgtest.c"
		LANG=C sed -i -- 's/!defined(OPENSSL_NO_ASYNC)/defined(HAVE_FORK)/' "./crypto/async/arch/async_posix.h"
	fi
	if [[ "$OPENSSL_VERSION" = "openssl-3.0"* ]]; then
		# LANG=C sed -i -- 's/!defined(OPENSSL_NO_POSIX_IO)/defined(HAVE_FORK)/' "./apps/ocsp.c"
		LANG=C sed -i -- 's/fork()/-1/' "./apps/speed.c"
		LANG=C sed -i -- 's/fork()/-1/' "./apps/lib/http_server.c"
		LANG=C sed -i -- 's/fork()/-1/' "./test/drbgtest.c"
		LANG=C sed -i -- 's/undef NO_FORK/define NO_FORK/' "./crypto/async/arch/async_posix.h"
		export CC="${BUILD_TOOLS}/usr/bin/gcc -arch ${ARCH}"
	fi

	# Patch Configure to build for tvOS, not iOS
	LANG=C sed -i -- 's/D\_REENTRANT\:iOS/D\_REENTRANT\:tvOS/' "./Configure"
	chmod u+x ./Configure

	if [[ "${ARCH}" == "x86_64" ]]; then
		if [[ "$OPENSSL_VERSION" = "openssl-1.0"* ]]; then
			./Configure no-asm darwin64-x86_64-cc --openssldir="/tmp/${OPENSSL_VERSION}-tvOS-${ARCH}" $CUSTOMCONFIG &> "/tmp/${OPENSSL_VERSION}-tvOS-${ARCH}.log"
		else
			./Configure no-asm darwin64-x86_64-cc -no-shared --prefix="/tmp/${OPENSSL_VERSION}-tvOS-${ARCH}" --openssldir="/tmp/${OPENSSL_VERSION}-tvOS-${ARCH}" $CUSTOMCONFIG &> "/tmp/${OPENSSL_VERSION}-tvOS-${ARCH}.log"
		fi
	else
		if [[ "$OPENSSL_VERSION" = "openssl-1.0"* ]]; then
			./Configure iphoneos-cross --openssldir="/tmp/${OPENSSL_VERSION}-tvOS-${ARCH}" $CUSTOMCONFIG &> "/tmp/${OPENSSL_VERSION}-tvOS-${ARCH}.log"
		else
			./Configure iphoneos-cross DSO_LDFLAGS=-fembed-bitcode --prefix="/tmp/${OPENSSL_VERSION}-tvOS-${ARCH}" -no-shared --openssldir="/tmp/${OPENSSL_VERSION}-tvOS-${ARCH}" $CUSTOMCONFIG &> "/tmp/${OPENSSL_VERSION}-tvOS-${ARCH}.log"
		fi
	fi
	# add -isysroot to CC=
	if [[ "$OPENSSL_VERSION" = "openssl-1.0"* ]]; then
		sed -ie "s!^CFLAG=!CFLAG=-isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -mtvos-version-min=${TVOS_MIN_SDK_VERSION} !" "Makefile"
	else
		sed -ie "s!^CFLAGS=!CFLAGS=-isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -mtvos-version-min=${TVOS_MIN_SDK_VERSION} !" "Makefile"
	fi

	make -j${CORES} >> "/tmp/${OPENSSL_VERSION}-tvOS-${ARCH}.log" 2>&1
	make install_sw >> "/tmp/${OPENSSL_VERSION}-tvOS-${ARCH}.log" 2>&1
	make clean >> "/tmp/${OPENSSL_VERSION}-tvOS-${ARCH}.log" 2>&1
	popd > /dev/null

	# Clean up exports
	export CC=""
	export CXX=""
	export CFLAGS=""
	export LDFLAGS=""
	export CPPFLAGS=""
}

buildTVOSsim()
{
	ARCH=$1

	pushd . > /dev/null
	cd "${OPENSSL_VERSION}"

	PLATFORM="AppleTVSimulator"
	TARGET="darwin64-${ARCH}-cc"
	RUNTARGET="-target ${ARCH}-apple-tvos${TVOS_MIN_SDK_VERSION}-simulator"

	export $PLATFORM
	export SYSROOT=$(xcrun --sdk appletvsimulator --show-sdk-path)
	export BUILD_TOOLS="${DEVELOPER}"
	export CC="${BUILD_TOOLS}/usr/bin/gcc -fembed-bitcode -arch ${ARCH}"
	export LC_CTYPE=C


	export CFLAGS=" -Os -fembed-bitcode -arch ${ARCH} ${RUNTARGET} "
	export LDFLAGS=" -arch ${ARCH} -isysroot ${SYSROOT}"
	export CPPFLAGS=" -I.. -isysroot ${SYSROOT}"
	export CXX="${BUILD_TOOLS}/usr/bin/gcc"

	echo -e "${subbold} Building ${OPENSSL_VERSION} for ${PLATFORM} ${TVOS_SDK_VERSION} ${archbold}${ARCH}${dim} (tvOS Simulator ${TVOS_MIN_SDK_VERSION})"

	# Patch apps/speed.c to not use fork() since it's not available on tvOS
	LANG=C sed -i -- 's/define HAVE_FORK 1/define HAVE_FORK 0/' "./apps/speed.c"
	if [[ "$OPENSSL_VERSION" = "openssl-1.1.1"* ]]; then
		LANG=C sed -i -- 's/!defined(OPENSSL_NO_POSIX_IO)/defined(HAVE_FORK)/' "./apps/ocsp.c"
		LANG=C sed -i -- 's/fork()/-1/' "./apps/ocsp.c"
		LANG=C sed -i -- 's/fork()/-1/' "./test/drbgtest.c"
		LANG=C sed -i -- 's/!defined(OPENSSL_NO_ASYNC)/defined(HAVE_FORK)/' "./crypto/async/arch/async_posix.h"
	fi
	if [[ "$OPENSSL_VERSION" = "openssl-3.0"* ]]; then
		# LANG=C sed -i -- 's/!defined(OPENSSL_NO_POSIX_IO)/defined(HAVE_FORK)/' "./apps/ocsp.c"
		LANG=C sed -i -- 's/fork()/-1/' "./apps/speed.c"
		LANG=C sed -i -- 's/fork()/-1/' "./apps/lib/http_server.c"
		LANG=C sed -i -- 's/fork()/-1/' "./test/drbgtest.c"
		LANG=C sed -i -- 's/undef NO_FORK/define NO_FORK/' "./crypto/async/arch/async_posix.h"
		export CC="${BUILD_TOOLS}/usr/bin/gcc -arch ${ARCH}"
		export CFLAGS=" -Os -arch ${ARCH} ${RUNTARGET} "
	fi

	# Patch Configure to build for tvOS, not iOS
	LANG=C sed -i -- 's/D\_REENTRANT\:iOS/D\_REENTRANT\:tvOS/' "./Configure"
	chmod u+x ./Configure

	if [[ "$OPENSSL_VERSION" = "openssl-1.0"* ]]; then
		./Configure no-asm  --openssldir="/tmp/${OPENSSL_VERSION}-tvOS-Simulator-${ARCH}" $CUSTOMCONFIG &> "/tmp/${OPENSSL_VERSION}-tvOS-Simulator-${ARCH}.log"
	else
		./Configure no-asm  ${TARGET} -no-shared --prefix="/tmp/${OPENSSL_VERSION}-tvOS-Simulator-${ARCH}" --openssldir="/tmp/${OPENSSL_VERSION}-tvOS-Simulator-${ARCH}" $CUSTOMCONFIG &> "/tmp/${OPENSSL_VERSION}-tvOS-Simulator-${ARCH}.log"
	fi

	# add -isysroot to CC=
	if [[ "$OPENSSL_VERSION" = "openssl-1.0"* ]]; then
		sed -ie "s!^CFLAG=!CFLAG=-isysroot ${SYSROOT} -mtvos-version-min=${TVOS_MIN_SDK_VERSION} !" "Makefile"
	else
		sed -ie "s!^CFLAGS=!CFLAGS=-isysroot ${SYSROOT} -mtvos-version-min=${TVOS_MIN_SDK_VERSION} !" "Makefile"
	fi

	make -j${CORES} >> "/tmp/${OPENSSL_VERSION}-tvOS-Simulator-${ARCH}.log" 2>&1
	make install_sw >> "/tmp/${OPENSSL_VERSION}-tvOS-Simulator-${ARCH}.log" 2>&1
	make clean >> "/tmp/${OPENSSL_VERSION}-tvOS-Simulator-${ARCH}.log" 2>&1
	popd > /dev/null

	# Clean up exports
	export CC=""
	export CXX=""
	export CFLAGS=""
	export LDFLAGS=""
	export CPPFLAGS=""
}

# echo -e "${bold}Cleaning up${dim}"
# rm -rf include/openssl/* lib/*

mkdir -p Mac/lib
mkdir -p Catalyst/lib
mkdir -p iOS/lib
mkdir -p iOS-simulator/lib
mkdir -p iOS-fat/lib
mkdir -p tvOS-fat/lib
mkdir -p tvOS/lib
mkdir -p Mac/include/openssl/
mkdir -p Catalyst/include/openssl/
mkdir -p iOS/include/openssl/
mkdir -p iOS-simulator/include/openssl/
mkdir -p iOS-fat/include/openssl/
mkdir -p tvOS/include/openssl/
mkdir -p tvOS-simulator/lib
mkdir -p tvOS-simulator/include/openssl/

rm -rf "/tmp/openssl"
rm -rf "/tmp/${OPENSSL_VERSION}-*"
rm -rf "/tmp/${OPENSSL_VERSION}-*.log"

rm -rf "${OPENSSL_VERSION}"

if [ ! -e ${OPENSSL_VERSION}.tar.gz ]; then
	echo -e "${dim}Downloading ${OPENSSL_VERSION}.tar.gz"
	curl -LOs https://www.openssl.org/source/${OPENSSL_VERSION}.tar.gz
else
	echo -e "${dim}Using ${OPENSSL_VERSION}.tar.gz"
fi

if [[ "$OPENSSL_VERSION" = "openssl-1.1.1"* || "$OPENSSL_VERSION" = "openssl-3"* ]]; then
	echo -e "${dim}** Building OpenSSL ${OPENSSL_VERSION} **"
else
	if [[ "$OPENSSL_VERSION" = "openssl-1.0."* ]]; then
		echo -e "${dim}** Building OpenSSL ${OPENSSL_VERSION} ** "
		echo -e "${alert}** WARNING: End of Life Version - Upgrade to 1.1.1 **${dim}"
	else
		echo -e "${alert}** WARNING: This build script has not been tested with $OPENSSL_VERSION **${dim}"
	fi
fi

echo -e "${dim}Unpacking openssl"
tar xfz "${OPENSSL_VERSION}.tar.gz"

if [ "$engine" == "1" ]; then
	echo -e "${dim}+ Activate Static Engine"
	sed -ie 's/\"engine/\"dynamic-engine/' ${OPENSSL_VERSION}/Configurations/15-ios.conf
fi

## Mac
echo -e "${bold}Building Mac libraries${dim}"
buildMac "x86_64"
buildMac "arm64"

echo -e "  ${dim}Copying headers and libraries"
cp /tmp/${OPENSSL_VERSION}-x86_64/include/openssl/* Mac/include/openssl/

lipo \
	"/tmp/${OPENSSL_VERSION}-x86_64/lib/libcrypto.a" \
	"/tmp/${OPENSSL_VERSION}-arm64/lib/libcrypto.a" \
	-create -output Mac/lib/libcrypto.a

lipo \
	"/tmp/${OPENSSL_VERSION}-x86_64/lib/libssl.a" \
	"/tmp/${OPENSSL_VERSION}-arm64/lib/libssl.a" \
	-create -output Mac/lib/libssl.a

## Catalyst
if [ $catalyst == "1" ]; then
	echo -e "${bold}Building Catalyst libraries${dim}"
	buildCatalyst "x86_64"
	buildCatalyst "arm64"

	echo -e "  ${dim}Copying headers and libraries"
	cp /tmp/${OPENSSL_VERSION}-catalyst-x86_64/include/openssl/* Catalyst/include/openssl/

	lipo \
		"/tmp/${OPENSSL_VERSION}-catalyst-x86_64/lib/libcrypto.a" \
		"/tmp/${OPENSSL_VERSION}-catalyst-arm64/lib/libcrypto.a" \
		-create -output Catalyst/lib/libcrypto.a

	lipo \
		"/tmp/${OPENSSL_VERSION}-catalyst-x86_64/lib/libssl.a" \
		"/tmp/${OPENSSL_VERSION}-catalyst-arm64/lib/libssl.a" \
		-create -output Catalyst/lib/libssl.a
fi

## tvOS
echo -e "${bold}Building tvOS libraries${dim}"
buildTVOS "arm64"

echo -e "  ${dim}Copying headers and libraries"
cp /tmp/${OPENSSL_VERSION}-tvOS-arm64/include/openssl/* tvOS/include/openssl/

lipo \
	"/tmp/${OPENSSL_VERSION}-tvOS-arm64/lib/libcrypto.a" \
	-create -output tvOS/lib/libcrypto.a

lipo \
	"/tmp/${OPENSSL_VERSION}-tvOS-arm64/lib/libssl.a" \
	-create -output tvOS/lib/libssl.a


echo -e "${bold}Building tvOS simulator libraries${dim}"
buildTVOSsim "arm64"
buildTVOSsim "x86_64"

lipo \
	"/tmp/${OPENSSL_VERSION}-tvOS-arm64/lib/libcrypto.a" \
	"/tmp/${OPENSSL_VERSION}-tvOS-Simulator-x86_64/lib/libcrypto.a" \
	-create -output tvOS-fat/lib/libcrypto.a

lipo \
	"/tmp/${OPENSSL_VERSION}-tvOS-arm64/lib/libssl.a" \
	"/tmp/${OPENSSL_VERSION}-tvOS-Simulator-x86_64/lib/libssl.a" \
	-create -output tvOS-fat/lib/libssl.a

echo -e "  ${dim}Copying headers and libraries"
cp /tmp/${OPENSSL_VERSION}-tvOS-Simulator-x86_64/include/openssl/* tvOS-simulator/include/openssl/

lipo \
	"/tmp/${OPENSSL_VERSION}-tvOS-Simulator-arm64/lib/libcrypto.a" \
	"/tmp/${OPENSSL_VERSION}-tvOS-Simulator-x86_64/lib/libcrypto.a" \
	-create -output tvOS-simulator/lib/libcrypto.a

lipo \
	"/tmp/${OPENSSL_VERSION}-tvOS-Simulator-arm64/lib/libssl.a" \
	"/tmp/${OPENSSL_VERSION}-tvOS-Simulator-x86_64/lib/libssl.a" \
	-create -output tvOS-simulator/lib/libssl.a

if [ $catalyst == "1" ]; then
	libtool -no_warning_for_no_symbols -static -o openssl-ios-x86_64-maccatalyst.a Catalyst/lib/libcrypto.a Catalyst/lib/libssl.a
fi

#echo -e "${bold}Cleaning up${dim}"
rm -rf /tmp/${OPENSSL_VERSION}-*
rm -rf ${OPENSSL_VERSION}

#reset trap
trap - INT TERM EXIT

#echo -e "${normal}Done"
