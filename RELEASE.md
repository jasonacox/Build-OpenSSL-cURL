# RELEASE NOTES

## 1.0.3 - SSLv3 Support and Enhancements

* Added SSLv3 support for security testing with `-3` flag. This allows verification that servers properly reject SSLv3 connections. Includes compatibility updates for OpenSSL 3.x which removed the `SSLv3_client_method()` function.
* Enhanced SSLv3 patch (`sslv3.patch`) to work with OpenSSL 3.x using `SSL_CTX_set_min_proto_version()` and `SSL_CTX_set_max_proto_version()` APIs.
* Added automatic SSLv3 support verification in build script when `-3` flag is used.
* Updated `iCurlHTTP.sh` script to copy all `.xcframework` folders from `archive/latest/xcframework` to support modern Xcode projects.
* Fixed libcurl-build.sh SSLv3 patching for curl 8.17.0+ to properly handle the new command-line argument processing in tool_getparam.c.
* Improved documentation with detailed patch file comments.

## 1.0.2 - Removal of armv7

* Removal of armv7/armv7s architecture support: Apple officially stopped supporting the creation of binaries for armv7/armv7s architectures with the release of Xcode 14 in June 2022. This means that new installations of Xcode will not be able to compile armv7 targets, which will break the build script.
* Removal of i386 architecture support: Apple officially stopped supporting the i386 architecture for new development in Xcode 10 (released in 2018), marking the end of 32-bit Intel support for both macOS and iOS simulators.

## 1.0.1 - Catalyst Fix

* Fix build issue where bitcode compile was happening for Catalyst target. 
* Bitcode compile is now deprecated. The build script disables it. This is in prep to remove all bitcode logic from the script in the next release.

## 1.0.0 - Platform Builds

* Updated build script to allow building for single platform targets: macOS, iOS or tvOS. Specify with `-p <platform>` switch. Default build is for "all" as it has been. 
    ```bash
    # Examples

    ./build.sh -p macos # Build only for macOS
    ./build.sh -p ios   # Build only for iOS
    ./build.sh -p tvos  # Build only for tvOS
    ./build.sh          # Build for all - macOS, iOS and tvOS

    # Disable Confirmation (auto-Yes)
    ./build.sh -y
    ```

* Added [examples apps](https://github.com/jasonacox/Build-OpenSSL-cURL/tree/master/example) for tvOS and macOS.
 <img width="641" alt="Image" src="https://github.com/user-attachments/assets/a05b76b5-2052-4033-be18-fdf45f7342e0" />

