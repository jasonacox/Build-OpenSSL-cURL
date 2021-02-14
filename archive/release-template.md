# Release ZZZLIBCURL Library and Headers

This release includes cURL+OpenSSL+Nghttp2 libraries and header files for MacOS, iOS and tvOS projects.

## Versions

    LIBCURL="ZZZLIBCURL"        # https://curl.haxx.se/download.html
    OPENSSL="ZZZOPENSSL"        # https://www.openssl.org/source/
    NGHTTP2="ZZZNGHTTP2"        # https://nghttp2.org/

## Archive

This directory contains the curl and openssl headers (in the `include` folder), the various *.a libraries built along with a MacOS binary for `curl` and `openssl` (built for intel and arm64).

    |__libcurl-ZZZLIBCURL-openssl-ZZZOPENSSL-nghttp2-ZZZNGHTTP2
        |__ README.md
        |__ bin/
        │   |__ curl*
        │   |__ curl-arm64*
        │   |__ curl-x86_64*
        │   |__ openssl*
        │   |__ openssl-arm64*
        │   |__ openssl-x86_64*
        |__ cacert.pem
        |__ framework/
        |__ include/
        │   |__ curl/
        │   |__ openssl/
        |__ lib/
        │   |__ Catalyst/
        │   |__ MacOS/
        │   |__ iOS/
        │   |__ iOS-fat/
        │   |__ iOS-simulator/
        │   |__ tvOS/
        │   |__ tvOS-simulator/
        |__ xcframework/
            |__ libcrypto.xcframework/
            │   |__ ios-arm64_arm64e_armv7_armv7s/
            │   |__ ios-arm64_i386_x86_64-simulator/
            │   |__ tvos-arm64/
            │   |__ tvos-arm64_x86_64-simulator/
            |__ libcurl.xcframework/
            │   |__ ios-arm64_arm64e_armv7_armv7s/
            │   |__ ios-arm64_i386_x86_64-simulator/
            │   |__ tvos-arm64/
            │   |__ tvos-arm64_x86_64-simulator/
            |__ libnghttp2.xcframework/
            │   |__ ios-arm64_arm64e_armv7_armv7s/
            │   |__ ios-arm64_i386_x86_64-simulator/
            │   |__ tvos-arm64/
            │   |__ tvos-arm64_x86_64-simulator/
            |__ libssl.xcframework/
                |__ ios-arm64_arm64e_armv7_armv7s/
                |__ ios-arm64_i386_x86_64-simulator/
                |__ tvos-arm64/
                |__ tvos-arm64_x86_64-simulator/

## Usage

 1. Copy headers to your project.
 2. Import appropriate libraries: "libssl.a", "libcrypto.a", "libcurl.a", "libnghttp2.a" *or*
    Alternative: Import appropriate *xcframework* folders into your project in Xcode.
 3. Reference Headers.
 4. Specifying the flag  "-lz" in "Other Linker Flags" (OTHER_LDFLAGS) setting in the "Linking" section in the Build settings of the target.
 5. Initialize curl in your code:

        #include <curl/curl.h>

        - (void)foo {    
            CURL* cURL = curl_easy_init();  
            ...  
        }