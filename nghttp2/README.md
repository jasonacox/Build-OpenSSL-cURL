# Build nghttp2  

Build nghttp2 for MacOS, Mac Catalyst, iOS and tvOS with Bitcode enabled for iOS, tvOS. 

## Build
The `nghttp2-build.sh` script attempts to pull down and build nghttp2.

Source: https://github.com/nghttp2/nghttp2/releases

Usage
=====

 1. Do "bash nghttp2-build.sh".
 2. Architecture Libraries are created in iOS/{ARCH}, Mac/{ARCH}, tvOS/{ARCH}, Catalyst/{ARCH}
 3. Multiple Architecture fat libraries are created in lib.
 4. To use libraries:
	cURL - You would use `--with-nghttp2={PATH-for-ARCH}`
	Xcode - Rename and add the appropriate FAT library to your project.
		Ex. iOS: `cp lib/libnghttp2_iOS.a ~/myProj/lib/libnghttp2.a `

The build script here is intended to be used with libcurl and openssl.
NOTE: pkg-config is required to build libcurl with nghttp2.  This script will attempt to install pkg-config with brew if it is missing.

## Manual Build

Automake is required (see automake-build.sh to install on MacOS)

```
#!/bin/bash
# Build nghttp2 from source

git clone https://github.com/tatsuhiro-t/nghttp2.git
cd nghttp2
autoreconf -i
automake
autoconf
./configure
make
sudo make install
```

## Credits

 Tatsuhiro Tsujikawa, nghttp2.org
   https://nghttp2.org https://github.com/nghttp2
 Jason Cox, @jasonacox
   https://github.com/jasonacox/Build-OpenSSL-cURL
 
