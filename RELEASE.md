# RELEASE NOTES

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

