# Build nghttp2  

Build nghttp2 for OS X, iOS and tvOS with Bitcode enabled for iOS, tvOS. 

## Build
The `nghttp2-build.sh` script attempts to pull down and build nghttp2.

Source: https://github.com/nghttp2/nghttp2/releases

Usage
=====

 1. Do "bash nghttp2-build.sh".
 2. Architecture Libraries are created in iOS/{ARCH}, Mac/{ARCH}, tvOS/{ARCH}
 3. Multiple Architecture fat libraries are created in lib.
 3. To use libraries:
	cURL - You would use `--with-nghttp2={PATH-for-ARCH}`
	Xcode - Rename and add the appropriate FAT library to your project.
		Ex. iOS: `cp lib/libnghttp2_iOS.a ~/myProj/lib/libnghttp2.a `

## Manual Build
```
# Get build requirements
# Some of these are used for the Python bindings
# this package also installs
sudo apt-get install g++ make binutils autoconf automake autotools-dev libtool pkg-config \
  zlib1g-dev libcunit1-dev libssl-dev libxml2-dev libev-dev libevent-dev libjansson-dev \
  libjemalloc-dev cython python3-dev python-setuptools

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

 Jason Cox, @jasonacox
   https://github.com/jasonacox/Build-OpenSSL-cURL
 
