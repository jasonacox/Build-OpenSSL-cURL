# Build-OpenSSL-cURL

[![Build Status](https://travis-ci.org/jasonacox/Build-OpenSSL-cURL.svg?branch=master)](https://travis-ci.org/jasonacox/Build-OpenSSL-cURL)

This Script builds OpenSSL, nghttp2 and libcurl for MacOS (OS X), Mac Catalyst, iOS and tvOS devices (x86_64, armv7, armv7s, arm64 and arm64e).  It includes patching for tvOS to not use fork() and adds HTTP2 support via nghttp2.

## News - Current State

* Mac Catalyst: This now optionally builds libraries for [Mac Catalyst](https://developer.apple.com/mac-catalyst/)
* Apple Silicon build progress: The script now builds OpenSSL and nghttp2 libraries for MacOS x86_64 and the new arm64 (apple silicon) targets, including iOS Simulator (x86_64 and arm64). [Beta]  Not complete: libcurl libraries and Mac Catalyst targets.

## Build

The `build.sh` script calls the three build scripts below (openssl, nghttp and curl) which download the specified release version, configure and build the libraries and binaries.  

The build script accepts several arguments to adjust versions and toggle features:

```
  ./build.sh [-o <OpenSSL version>] [-c <curl version>] [-n <nghttp2 version>] [-d] [-e] [-x] [-h]

         -o <version>   Build OpenSSL version (default 1.1.1d)
         -c <version>   Build curl version (default 7.68.0)
         -n <version>   Build nghttp2 version (default 1.40.0)
         -d             Compile without HTTP2 support
         -e             Compile with OpenSSL engine support
         -b             Compile without bitcode
         -m             Compile Mac Catalyst binaries [beta]"
         -x             No color output
         -h             Show usage
```

_OpenSSL Engine Note: By default, the OpenSSL source disables ENGINE support for iOS builds.  To force this active use this and the static engine support will be included:_ `./build.sh -e`

_Mac Catalyst Note: Static libraries can be built for Mac Catalyst. This requires a current version of Xcode (11.6+). To build Catalyst binaries use the switch:_ `./build.sh -m`

## Quick Start

1. Clone this Repo
2. Run the build script
3. Libraries and Binaries will be in the ./archive folder

```bash
git clone https://github.com/jasonacox/Build-OpenSSL-cURL.git
cd Build-OpenSSL-cURL
./build.sh
```

Default versions are specified in the `build.sh` script but you can specify the version you want to build via the command line, e.g.:

```bash
./build.sh -o 1.1.1g -c 7.72.0 -n 1.41.0
```

You can update the default version by editing this section in the `build.sh` script:

```bash
################################################
# EDIT this section to Select Default Versions #
################################################

OPENSSL="1.1.1g"	# https://www.openssl.org/source/
LIBCURL="7.72.0"	# https://curl.haxx.se/download.html
NGHTTP2="1.41.0"	# https://nghttp2.org/

################################################
```

## Details

### Dependencies
The build script requires:
* Xcode 7.1 or higher (10+ recommended)
* Xcode Command Line Tools
* pkg-config tool for nghttp2 (or `brew` to auto-install)

### OpenSSL
The `openssl-build.sh` script creates separate bitcode enabled target libraries for:
* Mac - x86-64
* iOS - iPhone (armv7, armv7s, arm64 and arm64e) and iPhoneSimulator (i386, x86-64)
* tvOS - AppleTVOS (arm64) and AppleTVSimulator (x86-64)

By default, the OpenSSL source disables ENGINE support for iOS builds.  To force this active use `build.sh -e`

The tvOS build has fork() disable as the AppleTV tvOS does not support fork(). 

	|____lib
	   |____libcrypto.a
	   |____libssl.a

NOTE: This script allows building the OpenSSL 1.1.1 and 1.0.2 series libraries.  The 1.0.2 series will be end of life soon so it is recommended that you use the new long term support (LTS) 1.1.1 version.

### HTTP2 / nghttp2
The `nghttp2-build.sh` script builds the nghttp2 libraries used by libcurl for the HTTP2 protocol.
* Mac - x86-64
* iOS - armv7, armv7s, arm64, arm64e and iPhoneSimulator (i386, x86-64)
* tvOS - arm64 and AppleTVSimulator (x86-64)

Edit `build.sh` to change the default version of nghttp2 that will be downloaded and built or specify the version on the command line.

	build.sh -n 1.40.0 

Include the relevant library into your project. The pkg-config tool is required.  The build script tests for this and will attempt to install if it is missing. Rename the appropriate file to libnghttp2.a:

	|____lib
	   |____libnghttp2_iOS.a
	   |____libnghttp2_iOS-simulator.a
	   |____libnghttp2_iOS-fat.a    <-- Contains both iOS and iOS-simulator binaries
	   |____libnghttp2_Mac.a
	   |____libnghttp2_tvOS.a
	   |____libnghttp2_Catalyst.a

DISABLE HTTP2: The nghttp2 build can be disabled by using:

	build.sh -d

### cURL / libcurl
The `libcurl-build.sh` script create separate bitcode enabled targets libraries for:
* Mac - x86-64
* iOS - armv7, armv7s, arm64, arm64e and iPhoneSimulator (i386, x86-64)
* tvOS - arm64 and AppleTVSimulator (x86-64)

The curl build uses `--with-ssl` pointing to the above OpenSSL builds and `--with-nghttp2` pointing to the above nghttp2 builds..
Edit `build.sh` to change the version of cURL that will be downloaded and built or specify the version on the command line.

	build.sh -c 7.68.0 
	
Include the relevant library into your project.  Rename the appropriate file to libcurl.a:

	|____lib
	   |____libcurl_iOS.a
	   |____libcurl_iOS-simulator.a
	   |____libcurl_iOS-fat.a        <-- Contains both iOS and iOS-simulator binaries
	   |____libcurl_Mac.a
	   |____libcurl_tvOS.a
	   |____libcurl_Catalyst.a

NOTE: By default, this script only builds bitcode versions. To build non-bitcode versions:

	build.sh -b

### Xcode

Xcode7.1b or later is required for the tvOS SDK.

To include the OpenSSL and libcurl libraries in your Xcode projects, import the appropriate libraries for your project from:
* Curl - curl/lib [rename to libcurl.a]
* OpenSSL - openssl/Mac/lib, openssl/iOS/lib, openssl/tvOS/lib
* nghttp2 (HTTP2) - nghttp2/lib [rename to libnghttp2.a]

See the example 'iOS Test App'.

### Usage

 1. Clone this Repo 
 2. Run `build.sh` 
 3. Libraries are created in curl/lib, openssl/*/lib, and nghttp2/lib or you can find them in the archives folder.
 4. Copy libs and headers to your project.
 5. Import appropriate "libssl.a", "libcrypto.a", "libcurl.a", "libnghttp2.a".
 6. Reference Headers, "Headers/openssl", "Headers/curl".
 7. Specifying the flag  "-lz" in "Other Linker Flags" (OTHER_LDFLAGS) setting in the "Linking" section in the Build settings of the target.
 8. To use cURL, see below:

        #include <curl/curl.h>

        - (void)foo {    
            CURL* cURL = curl_easy_init();  
            ...  
        }

NOTE: You may need to edit the `curlbuild.h` header if you get an error similar to this: `'curl_rule_01' declared as an array with a negative size`

curlbuild.h

	/* The size of `long', as computed by sizeof. */
	// ADD Condition for 64 Bit
	#ifdef __LP64__
	#define CURL_SIZEOF_LONG 8
	#else
	#define CURL_SIZEOF_LONG 4
	#endif

You may also need to edit this section:

	/* Signed integral data type used for curl_off_t. */
	//#define CURL_TYPEOF_CURL_OFF_T long
	//ADD Condition for 64 Bit
	#define CURL_TYPEOF_CURL_OFF_T int64_t

`curl/curlbuild-ios-universal.h` is a universal example, tested on iOS platforms, made out of libcurl-7.50.3. Check the diff between this file and `curlbuild.h` before using it.

### Example Apps

Example Xcode project "iOS Test App" is located in the example folder.  This project builds an iPhone Objective C App using libcurl, openssl, and nghttp2 libraries. The app provides a simple single text field interface for URL input and produces a curl response.

The Example app project builds an iOS, iOS Simulator and Mac Catalyst target.

### Tree

	|
	|____archive
	|
	|____curl
	| |____lib
	| |____libcurl-build.sh
	|
	|____example
	| |____iOS Test App
	|
	|____nghttp2
	| |____nghttp2-build.sh
	|
	|____openssl
	| |____openssl-build.sh
	|
	|____build.sh
	|____clean.sh


### Architectures in Mach-O Universal (Fat) Libraries

	xcrun -sdk iphoneos lipo -info openssl/*/lib/*.a
	xcrun -sdk iphoneos lipo -info nghttp2/lib/*.a
	xcrun -sdk iphoneos lipo -info curl/lib/*.a

* Catalyst
	* openssl/Catalyst/lib/libcrypto.a are: x86_64 
	* openssl/Catalyst/lib/libssl.a are: x86_64 
    * nghttp2/lib/libnghttp2_Catalyst.a are: x86_64 
	* curl/lib/libcurl_Catalyst.a are: x86_64 

* Mac
	* openssl/Mac/lib/libcrypto.a are: x86_64 
	* openssl/Mac/lib/libssl.a are: x86_64 
	* nghttp2/lib/libnghttp2_Mac.a are: x86_64 
	* curl/lib/libcurl_Mac.a are: x86_64 

* iOS
	* openssl/iOS-fat/lib/libcrypto.a are: armv7 armv7s i386 x86_64 arm64 arm64e 
	* openssl/iOS-fat/lib/libssl.a are: armv7 armv7s i386 x86_64 arm64 arm64e 
	* openssl/iOS-simulator/lib/libcrypto.a are: i386 x86_64 
	* openssl/iOS-simulator/lib/libssl.a are: i386 x86_64 
	* openssl/iOS/lib/libcrypto.a are: armv7 armv7s arm64 arm64e 
	* openssl/iOS/lib/libssl.a are: armv7 armv7s arm64 arm64e 
	* nghttp2/lib/libnghttp2_iOS-fat.a are: armv7 armv7s i386 x86_64 arm64 arm64e 
	* nghttp2/lib/libnghttp2_iOS-simulator.a are: i386 x86_64 
	* nghttp2/lib/libnghttp2_iOS.a are: armv7 armv7s arm64 arm64e 
	* curl/lib/libcurl_iOS-fat.a are: armv7 armv7s i386 x86_64 arm64 arm64e 
	* curl/lib/libcurl_iOS-simulator.a are: i386 x86_64 
	* curl/lib/libcurl_iOS.a are: armv7 armv7s arm64 arm64e 

* tvOS
	* openssl/tvOS/lib/libcrypto.a are: x86_64 arm64 
	* openssl/tvOS/lib/libssl.a are: x86_64 arm64 
	* nghttp2/lib/libnghttp2_tvOS.a are: x86_64 arm64 
	* curl/lib/libcurl_tvOS.a are: x86_64 arm64 

* Consolidated OpenSSL Libraries for iOS
	* openssl/openssl-ios-armv7_armv7s_arm64_arm64e.a are: armv7 armv7s arm64 arm64e 
	* openssl/openssl-ios-x86_64-simulator.a are: i386 x86_64 
	* openssl/openssl-ios-x86_64-maccatalyst.a is architecture: x86_64

### Archive

The `build.sh` script will create an ./archive folder and store all the *.a libraries built along with the header files and a MacOS binaries for `curl` and `openssl`.

	   |___libcurl-7.66.0-openssl-1.1.1d-nghttp2-1.39.2
             |
             |____cacert.pem
             |
             |____bin/
             |  |____openssl*
             |  |____curl*
             |
             |____framework/
             |
             |____lib/
             |  |____Catalyst/
             |  |____iOS/
             |  |____iOS-simulator/
             |  |____iOS-fat/        <-- Contains universal iOS and iOS-simulator binaries
             |  |____MacOS/
             |  |____tvOS/
             |
             |____include/
                |____openssl/
                |____curl/

## Download Compressed Archives

Previous builds can be downloaded form the Github releases for this project: https://github.com/jasonacox/Build-OpenSSL-cURL/releases
 
## License

The MIT License is used for this project.  See LICENSE file.

## Credits & Thanks

* Daniel Stenberg, @bagder, author and maintainer of cURL and libcurl
   https://daniel.haxx.se/
* OpenSSL Software Foundation, maintainer of OpenSSL
   https://www.openssl.org/
* Tatsuhiro Tsujikawa, @tatsuhiro_t, author and maintainer of nghttp2 library and tools
   https://github.com/nghttp2/nghttp2

* Felix Schwarz, IOSPIRIT GmbH, @@felix_schwarz.
   https://gist.github.com/c61c0f7d9ab60f53ebb0.git
* Bochun Bai
   https://github.com/sinofool/build-libcurl-ios
* Stefan Arentz
   https://github.com/st3fan/ios-openssl
* Felix Schulze
   https://github.com/x2on/OpenSSL-for-iPhone/blob/master/build-libssl.sh
* James Moore
   https://gist.github.com/foozmeat/5154962
* Peter Steinberger, PSPDFKit GmbH, @steipete.
   https://gist.github.com/felix-schwarz/c61c0f7d9ab60f53ebb0
* Tom Peeters, Tommy2d, Brightfish, Mac Catalyst build support
   https://github.com/tommy2d

* Jason Cox, @jasonacox
   https://github.com/jasonacox/Build-OpenSSL-cURL

## Build Troubleshooting Tips

The AppleTVOS curl build may fail due to a macports "ar" program being picked up (it was in the path - You will see a log message about /opt/local/bin/ar failing in the curl log). A quick cleanup of the path (so that the build uses /usr/bin/ar) fixed the problem.  - Thanks to Preston Jennings (prestonj) for this tip.

If the `build.sh` script fails during iOS build phase with an error "C Compiler cannot create executables" this is likely due to not having a clean installation of the Xcode command line tools.  Launch Xcode and re-install the command line tools. 

If you see "FATAL ERROR" during the nghttp2 build phase, this is likely due to not having 'pkg-config' tools installed.  Install manually or install 'brew' to have the script install it for you.

If you are on a new macOS installation and wonder why the build is failing, you might need to set the correct path for the command line tools:

	xcode-select --switch /Applications/Xcode.app
