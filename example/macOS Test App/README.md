# macOS Test App

This is a test app for macOS using the curl, openssl and nghttp2 libraries.

## Screenshots

macOS Test Build

<img width="641" alt="Image" src="https://github.com/user-attachments/assets/a05b76b5-2052-4033-be18-fdf45f7342e0" />

## Build Instructions

The `libs` and `include` folders will be created during the build. These are required to build and run the Test application in Xcode. Build the libraries with this command:

```bash
# Build for all platforms
./build.sh

# Option: Build only macOS
./build.sh -p macos
```

Load and build the project using Xcode. Example lib binaries (xcframework) and header files are included but will be replaced when you run the build script. 

## New Project Setup Details

If you are setting up a new Xcode project, there are few things you will need to set up. These are all set up for you already in the xcodeproj file:

* You will also need to add the xcframework files (libs) and header files (include). You will also need to add libz.tbd, liblapd.tgb, CoreFoundation.framework, and SystemConfiguraiton.framework to the Xcode project ("General"). 
 <img width="482" alt="Image" src="https://github.com/user-attachments/assets/29fd3b15-f130-41cd-91d8-689a6b8b3f50" />

* You will need to allow "Outgoing Connection (Client)" in the "Signing & Capabilities" of the project target "Sandbox" settings.
 <img width="482" alt="Image" src="https://github.com/user-attachments/assets/cd7f5e68-bc3e-4b5c-94d6-cb44c4c2ad23" />

