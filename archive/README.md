# Build-OpenSSL-cURL Binaries 

The `build.sh` script stores the builds in this archive directory. The directory names are based on the version of the releases of OpenSSL, nghttp2 and libcurl and include the libraries for MacOS, Mac Catalyst, iOS and tvOS.  

## Build Your Own or Use These

See the `build.sh` script in parent directory.

## Download Compressed Archives

Previous builds can be downloaded form the Github releases for this project: https://github.com/jasonacox/Build-OpenSSL-cURL/releases

## Archive

This directory contains the curl and openssl headers (in the `include` folder), the various *.a and xcframework libraries built along with a MacOS binary for `curl` and `openssl`.

    archive
        |__ bin/
        │   |__ curl*
        │   |__ curl-arm64*
        │   |__ curl-x86_64*
        │   |__ openssl*
        │   |__ openssl-arm64*
        │   |__ openssl-x86_64*
        |
        |__ cacert.pem
        |
        |__ include/
        │   |__ curl/
        │   |__ openssl/
        |
        |__ lib/
        │   |__ Catalyst/
        │   |__ MacOS/
        │   |__ iOS/
        │   |__ iOS-fat/
        │   |__ iOS-simulator/
        │   |__ tvOS/
        │   |__ tvOS-simulator/
        |
        |__ xcframework/
            |__ libcrypto.xcframework/
            |__ libcurl.xcframework/
            |__ libnghttp2.xcframework/
            |__ libssl.xcframework/

## License

The MIT License is used for this project.  See LICENSE file.
