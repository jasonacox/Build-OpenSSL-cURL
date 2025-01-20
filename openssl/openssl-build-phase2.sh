#!/bin/bash
#
# This script downlaods and builds the iOS openSSL libraries with Bitcode enabled
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

# set trap to help debug build errors
trap 'echo -e "${alert}** ERROR with Build on line $LINENO ($0) - Check /tmp/openssl*.log${alertdim}"; tail -3 /tmp/openssl*.log' ERR TERM EXIT
trap 'exit 1' INT

# Set minimum OS versions for target
MACOS_X86_64_VERSION=""			# Empty = use host version
MACOS_ARM64_VERSION=""			# Min supported is MacOS 11.0 Big Sur
CATALYST_IOS="15.0"				# Min supported is iOS 15.0 for Mac Catalyst
IOS_MIN_SDK_VERSION="8.0"
IOS_SDK_VERSION=""
TVOS_MIN_SDK_VERSION="9.0"
TVOS_SDK_VERSION=""
catalyst="0"
VERSION="3.0.9"					# OpenSSL version default
BUILDFOR="all"

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
	echo -e "  ${subbold}$0${normal} [-v ${dim}<version>${normal}] [-s ${dim}<version>${normal}] [-t ${dim}<version>${normal}] [-i ${dim}<version>${normal}] [-a ${dim}<version>${normal}] [-u ${dim}<version>${normal}]  [-e] [-m] [-3] [-x] [-h]"
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
	echo "         -p   build only for specified platform (iOS, tvOS, macOS)" 
	echo "         -h   show usage"
	echo
	trap - INT TERM EXIT
	exit 127
}

engine=0

while getopts "v:s:t:i:a:u:p:emx3h\?" o; do
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
		p)
			BUILDFOR=$(echo "${OPTARG}" | tr '[:upper:]' '[:lower:]')
			# Check for valid platform
			if [ "$BUILDFOR" != "ios" ] && [ "$BUILDFOR" != "tvos" ] && [ "$BUILDFOR" != "macos" ]; then
				echo -e "${alert}Invalid platform requested${normal}: $BUILDFOR"
				echo "Please specify iOS, tvOS or macOS"
				exit 127
			fi
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

buildIOS()
{
	ARCH=$1

	pushd . > /dev/null
	cd "${OPENSSL_VERSION}"

	if [[ "${ARCH}" == "i386" || "${ARCH}" == "x86_64" ]]; then
		PLATFORM="iPhoneSimulator"
	else
		PLATFORM="iPhoneOS"
		#sed -ie "s!static volatile sig_atomic_t intr_signal;!static volatile intr_signal;!" "crypto/ui/ui_openssl.c"
	fi

	export $PLATFORM
	export CROSS_TOP="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
	export CROSS_SDK="${PLATFORM}${IOS_SDK_VERSION}.sdk"
	export BUILD_TOOLS="${DEVELOPER}"
	ADDCFLAG=""
	DSO_LDFLAGS="DSO_LDFLAGS=-fembed-bitcode"
	if [[ "$OPENSSL_VERSION" = "openssl-3"* ]]; then
		# disable bitcode for openssl 3
		BITCODE="nobitcode"
		export CC="${BUILD_TOOLS}/usr/bin/gcc -arch ${ARCH}"
		DSO_LDFLAGS=""
		if [[ "${ARCH}" == "armv7" || "${ARCH}" == "armv7s" ]]; then
		    # armv7 doesn't work with atomics
			ADDCFLAG="-DBROKEN_CLANG_ATOMICS "
		fi
	else
		export CC="${BUILD_TOOLS}/usr/bin/gcc -fembed-bitcode -arch ${ARCH}"
		BITCODE="bitcode"
	fi

	echo -e "${subbold}Building ${OPENSSL_VERSION} for ${PLATFORM} ${IOS_SDK_VERSION} ${archbold}${ARCH}${dim} (iOS ${IOS_MIN_SDK_VERSION}) ${BITCODE}"

	if [[ "$OPENSSL_VERSION" = "openssl-1.0"* ]]; then
		./Configure iphoneos-cross -no-shared --openssldir="/tmp/${OPENSSL_VERSION}-iOS-${ARCH}" $CUSTOMCONFIG &> "/tmp/${OPENSSL_VERSION}-iOS-${ARCH}.log"
	else
		./Configure iphoneos-cross $DSO_LDFLAGS --prefix="/tmp/${OPENSSL_VERSION}-iOS-${ARCH}" -no-shared --openssldir="/tmp/${OPENSSL_VERSION}-iOS-${ARCH}" $CUSTOMCONFIG &> "/tmp/${OPENSSL_VERSION}-iOS-${ARCH}.log"
	fi
	
	# add -isysroot to CC=
	if [[ "$OPENSSL_VERSION" = "openssl-1.0"* ]]; then
		sed -ie "s!^CFLAG=!CFLAG=-isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -miphoneos-version-min=${IOS_MIN_SDK_VERSION} !" "Makefile"
	else
		sed -ie "s!^CFLAGS=!CFLAGS=-isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -miphoneos-version-min=${IOS_MIN_SDK_VERSION} ${ADDCFLAG} !" "Makefile"
	fi

	make -j${CORES} >> "/tmp/${OPENSSL_VERSION}-iOS-${ARCH}.log" 2>&1
	make install_sw >> "/tmp/${OPENSSL_VERSION}-iOS-${ARCH}.log" 2>&1
	make clean >> "/tmp/${OPENSSL_VERSION}-iOS-${ARCH}.log" 2>&1
	popd > /dev/null

	# Clean up exports
	export PLATFORM=""
	export CC=""
	export CXX=""
	export CFLAGS=""
	export LDFLAGS=""
	export CPPFLAGS=""
	export CROSS_TOP=""
	export CROSS_SDK=""
	export BUILD_TOOLS=""
}

buildIOSsim()
{
	ARCH=$1

	pushd . > /dev/null
	cd "${OPENSSL_VERSION}"

	PLATFORM="iPhoneSimulator"
	export $PLATFORM

	TARGET="darwin-i386-cc"
	RUNTARGET=""
	MIPHONEOS="${IOS_MIN_SDK_VERSION}"
	if [[ $ARCH != "i386" ]]; then
		TARGET="darwin64-${ARCH}-cc"
		RUNTARGET="-target ${ARCH}-apple-ios${IOS_MIN_SDK_VERSION}-simulator"
			# e.g. -target arm64-apple-ios11.0-simulator
		#if [[ $ARCH == "arm64" ]]; then
		#	if (( $(echo "${MIPHONEOS} < 11.0" |bc -l) )); then
		#		MIPHONEOS="11.0"	# Min support for Apple Silicon is iOS 11.0 
		#	fi
		#fi
	fi

	# set up exports for build 
	if [[ "$OPENSSL_VERSION" = "openssl-3"* ]]; then
		if [[ "${ARCH}" == "armv7" || "${ARCH}" == "armv7s" || "${ARCH}" == "i386" ]]; then
		    # armv7 and i386 doesn't work with atomic
			export CFLAGS=" -Os -miphoneos-version-min=${MIPHONEOS} -DBROKEN_CLANG_ATOMICS -arch ${ARCH} ${RUNTARGET} "
		else
			export CFLAGS=" -Os -miphoneos-version-min=${MIPHONEOS} ${ADDCFLAG} -arch ${ARCH} ${RUNTARGET} "
		fi
	else
		export CFLAGS=" -Os -miphoneos-version-min=${MIPHONEOS} -fembed-bitcode -arch ${ARCH} ${RUNTARGET} "
	fi
	export LDFLAGS=" -arch ${ARCH} -isysroot ${DEVELOPER}/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk "
	export CPPFLAGS=" -I.. -isysroot ${DEVELOPER}/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk "
	export CROSS_TOP="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
	export CROSS_SDK="${PLATFORM}${IOS_SDK_VERSION}.sdk"
	export BUILD_TOOLS="${DEVELOPER}"
	export CC="${BUILD_TOOLS}/usr/bin/gcc"
	export CXX="${BUILD_TOOLS}/usr/bin/gcc"

	echo -e "${subbold}Building ${OPENSSL_VERSION} for ${PLATFORM} ${iOS_SDK_VERSION} ${archbold}${ARCH}${dim} (iOS ${MIPHONEOS})"

	# configure
	if [[ "$OPENSSL_VERSION" = "openssl-1.0"* ]]; then
		./Configure no-asm ${TARGET} -no-shared --openssldir="/tmp/${OPENSSL_VERSION}-iOS-Simulator-${ARCH}" $CUSTOMCONFIG &> "/tmp/${OPENSSL_VERSION}-iOS-Simulator-${ARCH}.log"
	else
		./Configure no-asm ${TARGET} -no-shared --prefix="/tmp/${OPENSSL_VERSION}-iOS-Simulator-${ARCH}" --openssldir="/tmp/${OPENSSL_VERSION}-iOS-Simulator-${ARCH}" $CUSTOMCONFIG &> "/tmp/${OPENSSL_VERSION}-iOS-Simulator-${ARCH}.log"
	fi

	# add -isysroot to CC=
	# no longer needed with exports
	#if [[ "$OPENSSL_VERSION" = "openssl-1.1.1"* ]]; then
	#	sed -ie "s!^CFLAGS=!CFLAGS=-isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -miphoneos-version-min=${IOS_MIN_SDK_VERSION} !" "Makefile"
	#else
	#	sed -ie "s!^CFLAG=!CFLAG=-isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -miphoneos-version-min=${IOS_MIN_SDK_VERSION} !" "Makefile"
	#fi

	# make
	make -j${CORES} >> "/tmp/${OPENSSL_VERSION}-iOS-Simulator-${ARCH}.log" 2>&1
	make install_sw >> "/tmp/${OPENSSL_VERSION}-iOS-Simulator-${ARCH}.log" 2>&1
	make clean >> "/tmp/${OPENSSL_VERSION}-iOS-Simulator-${ARCH}.log" 2>&1
	popd > /dev/null

	# Clean up exports
	export PLATFORM=""
	export CC=""
	export CXX=""
	export CFLAGS=""
	export LDFLAGS=""
	export CPPFLAGS=""
	export CROSS_TOP=""
	export CROSS_SDK=""
	export BUILD_TOOLS=""
}

#echo -e "${bold}Cleaning up${dim}"
#rm -rf include/openssl/* lib/*

mkdir -p Mac/lib
mkdir -p Catalyst/lib
mkdir -p iOS/lib
mkdir -p iOS-simulator/lib
mkdir -p iOS-fat/lib
mkdir -p tvOS/lib
mkdir -p Mac/include/openssl/
mkdir -p Catalyst/include/openssl/
mkdir -p iOS/include/openssl/
mkdir -p iOS-simulator/include/openssl/
mkdir -p iOS-fat/include/openssl/
mkdir -p tvOS/include/openssl/

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

# iOS
if [ $BUILDFOR == "ios" ] || [ $BUILDFOR == "all" ]; then
	echo -e "${bold}Building iOS libraries${dim}"

	buildIOS "armv7"
	buildIOS "armv7s"
	buildIOS "arm64"
	buildIOS "arm64e"

	buildIOSsim "i386"
	buildIOSsim "x86_64"
	buildIOSsim "arm64"

	echo -e "  ${dim}Copying headers and libraries"
	cp /tmp/${OPENSSL_VERSION}-iOS-arm64/include/openssl/* iOS/include/openssl/

	lipo \
		"/tmp/${OPENSSL_VERSION}-iOS-armv7/lib/libcrypto.a" \
		"/tmp/${OPENSSL_VERSION}-iOS-armv7s/lib/libcrypto.a" \
		"/tmp/${OPENSSL_VERSION}-iOS-arm64/lib/libcrypto.a" \
		"/tmp/${OPENSSL_VERSION}-iOS-arm64e/lib/libcrypto.a" \
		-create -output iOS/lib/libcrypto.a

	lipo \
		"/tmp/${OPENSSL_VERSION}-iOS-armv7/lib/libssl.a" \
		"/tmp/${OPENSSL_VERSION}-iOS-armv7s/lib/libssl.a" \
		"/tmp/${OPENSSL_VERSION}-iOS-arm64/lib/libssl.a" \
		"/tmp/${OPENSSL_VERSION}-iOS-arm64e/lib/libssl.a" \
		-create -output iOS/lib/libssl.a


	cp /tmp/${OPENSSL_VERSION}-iOS-Simulator-x86_64/include/openssl/* iOS-simulator/include/openssl/

	lipo \
		"/tmp/${OPENSSL_VERSION}-iOS-Simulator-i386/lib/libcrypto.a" \
		"/tmp/${OPENSSL_VERSION}-iOS-Simulator-x86_64/lib/libcrypto.a" \
		"/tmp/${OPENSSL_VERSION}-iOS-Simulator-arm64/lib/libcrypto.a" \
		-create -output iOS-simulator/lib/libcrypto.a

	lipo \
		"/tmp/${OPENSSL_VERSION}-iOS-Simulator-i386/lib/libssl.a" \
		"/tmp/${OPENSSL_VERSION}-iOS-Simulator-x86_64/lib/libssl.a" \
		"/tmp/${OPENSSL_VERSION}-iOS-Simulator-arm64/lib/libssl.a" \
		-create -output iOS-simulator/lib/libssl.a

	cp /tmp/${OPENSSL_VERSION}-iOS-arm64/include/openssl/* iOS-fat/include/openssl/

	lipo \
		"/tmp/${OPENSSL_VERSION}-iOS-armv7/lib/libcrypto.a" \
		"/tmp/${OPENSSL_VERSION}-iOS-armv7s/lib/libcrypto.a" \
		"/tmp/${OPENSSL_VERSION}-iOS-arm64/lib/libcrypto.a" \
		"/tmp/${OPENSSL_VERSION}-iOS-arm64e/lib/libcrypto.a" \
		"/tmp/${OPENSSL_VERSION}-iOS-Simulator-i386/lib/libcrypto.a" \
		"/tmp/${OPENSSL_VERSION}-iOS-Simulator-x86_64/lib/libcrypto.a" \
		-create -output iOS-fat/lib/libcrypto.a

	lipo \
		"/tmp/${OPENSSL_VERSION}-iOS-armv7/lib/libssl.a" \
		"/tmp/${OPENSSL_VERSION}-iOS-armv7s/lib/libssl.a" \
		"/tmp/${OPENSSL_VERSION}-iOS-arm64/lib/libssl.a" \
		"/tmp/${OPENSSL_VERSION}-iOS-arm64e/lib/libssl.a" \
		"/tmp/${OPENSSL_VERSION}-iOS-Simulator-x86_64/lib/libssl.a" \
		"/tmp/${OPENSSL_VERSION}-iOS-Simulator-i386/lib/libssl.a" \
		-create -output iOS-fat/lib/libssl.a

	echo -e "  ${dim}Creating combined OpenSSL libraries for iOS"
	libtool -no_warning_for_no_symbols -static -o openssl-ios-armv7_armv7s_arm64_arm64e.a iOS/lib/libcrypto.a iOS/lib/libssl.a
	libtool -no_warning_for_no_symbols -static -o openssl-ios-i386_x86_64_arm64-simulator.a iOS-simulator/lib/libcrypto.a iOS-simulator/lib/libssl.a
fi

echo -e "${bold}Cleaning up${dim}"
rm -rf /tmp/${OPENSSL_VERSION}-*
rm -rf ${OPENSSL_VERSION}

#reset trap
trap - INT TERM EXIT

#echo -e "${normal}Done"
