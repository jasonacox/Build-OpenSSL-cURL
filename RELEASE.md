# RELEASE NOTES

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

