# Build-OpenSSL-cURL

Build OpenSSL and libcurl for OS X, iOS and tvOS with Bitcode enabled for iOS, tvOS.  Includes patching for tvOS to not use fork(). 

## Build
The `build.sh` script calls two build scripts:

## OpenSSL
The `openssl-build.sh` script creates separate bitcode enabled target libraries for:
* Mac - x86-64
* iOS - iPhone (armv7, armv7s, arm64) and iPhoneSimulator (i386, x86-64)
* tvOS - AppleTVOS (arm64) and AppleTVSimulator (x86-64)

The tvOS build has fork() disable as the AppleTV tvOS does not support fork(). 
Edit `openssl-build.sh` to change the version of OpenSSL that will be downloaded and built.

	|____lib
	   |____libcrypto.a
	   |____libssl.a

## cURL / libcurl
The `libcurl-build.sh` script create separate bitcode enabled targets libraries for:
* Mac - x86-64
* iOS - armv7, armv7s, arm64 and iPhoneSimulator (i386, x86-64)
* tvOS - arm64 and AppleTVSimulator (x86-64)

The curl build uses `--with-ssl` pointing to the above OpenSSL builds.
Edit `libcurl-build.sh` to change the verion of cURL that will be downloaded and built.

	|____lib
	   |____libcurl_iOS.a
	   |____libcurl_Mac.a
	   |____libcurl_tvOS.a


## Xcode

Xcode7.1b or later is required for the tvOS SDK.

To include the OpenSSL and libcurl libraries in your Xcode projects, import the following appropriate libraries for your project:
* Curl - curl/lib
* OpenSSL - openssl/Mac/lib, openssl/iOS/lib, openssl/tvOS/lib

Usage
=====

 1. Do "sh build.sh"
 2. Libraries are created in curl/lib, openssl/*/lib
 3. Copy libs and headers to your project.
 4. Import appropriate "libssl.a", "libcrypto.a", "libcurl.a".
 5. Reference Headers, "Headers/openssl", "Headers/curl".
 6. Specifying the flag  "-lz" in "Other Linker Flags" (OTHER_LDFLAGS) setting in the "Linking" section in the Build settings of the target.
 7. To use cURL, see below:

        #include <curl/curl.h>

        - (void)foo {    
            CURL* cURL = curl_easy_init();  
            ...  
        }


## Tree
	|____curl
	| |____include
	| | |____curl
	| |____lib
	|   |____libcurl_iOS.a
	|   |____libcurl_Mac.a
	|   |____libcurl_tvOS.a
	|
	|____openssl
	  |____iOS
	  | |____include
	  | | |____openssl
	  | |____lib
	  |   |____libcrypto.a
	  |   |____libssl.a
	  |____Mac
	  | |____include
	  | | |____openssl
	  | |____lib
	  |   |____libcrypto.a
	  |   |____libssl.a
	  |____tvOS
	    |____include
	    | |____openssl
	    |____lib
	      |____libcrypto.a
	      |____libssl.a

