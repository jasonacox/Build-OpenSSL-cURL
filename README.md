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


## Architectures in Libraries

	xcrun -sdk iphoneos lipo -info openssl/*/lib/*.a
	xcrun -sdk iphoneos lipo -info curl/lib/*.a

* Mac
* curl/lib/libcurl_Mac.a are: x86_64 
* openssl/Mac/lib/libcrypto.a are: x86_64 
* openssl/Mac/lib/libssl.a are: x86_64 
* iOS
* curl/lib/libcurl_iOS.a are: armv7 armv7s i386 x86_64 arm64 
* openssl/iOS/lib/libcrypto.a are: armv7 i386 x86_64 arm64 
* openssl/iOS/lib/libssl.a are: armv7 i386 x86_64 arm64 
* tvOS
* curl/lib/libcurl_tvOS.a are: x86_64 arm64 
* openssl/tvOS/lib/libcrypto.a are: x86_64 arm64 
* openssl/tvOS/lib/libssl.a are: x86_64 arm64 

## Credits

 Felix Schwarz, IOSPIRIT GmbH, @@felix_schwarz.
   https://gist.github.com/c61c0f7d9ab60f53ebb0.git
 Bochun Bai
   https://github.com/sinofool/build-libcurl-ios
 Stefan Arentz
   https://github.com/st3fan/ios-openssl
 Felix Schulze
   https://github.com/x2on/OpenSSL-for-iPhone/blob/master/build-libssl.sh
 James Moore
   https://gist.github.com/foozmeat/5154962
 Peter Steinberger, PSPDFKit GmbH, @steipete.
   https://gist.github.com/felix-schwarz/c61c0f7d9ab60f53ebb0
 Jason Cox, @jasonacox
   https://github.com/jasonacox/Build-OpenSSL-cURL

## Build Troubleshooting Tips

The AppleTVOS curl build may fail due to a macports "ar" program being picked up (it was in the path - You will see a log message about /opt/local/bin/ar failing in the curl log). A quick cleanup of the path (so that the build uses /usr/bin/ar) fixed the problem.  - Thanks to Preston Jennings (prestonj) for this tip.

