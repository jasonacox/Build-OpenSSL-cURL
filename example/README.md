# Example Apps

These three example Xcode projects show how to incorporate the OpenSSL+Curl libraries into your code.

## iOS

The iOS Build [iOS Test App](./iOS%20Test%20App/)

<img width="400" alt="image" src="https://github.com/jasonacox/Build-OpenSSL-cURL/assets/836718/6de13ab3-b7fe-4017-bf6d-9cbde131c098">
<img width="400" alt="image" src="https://github.com/jasonacox/Build-OpenSSL-cURL/assets/836718/66806f0c-0915-4742-b71c-b683300082ae">

## tvOS

The tvOS Build [tvOS Test App](./tvOS%20Test%20App/)

<img width="641" alt="Image" src="https://github.com/user-attachments/assets/fd0b1e2b-6f2c-4295-853a-574dc8533461" />

## macOS

The macOS Build [macOS Test App](./macOS%20Test%20App/)

<img width="641" alt="Image" src="https://github.com/user-attachments/assets/a05b76b5-2052-4033-be18-fdf45f7342e0" />

## Build Notes

The Test Apps will not build without the required files in the `libs` and `include` folders. These are created during the build and will be installed by the script:

```bash
./build.sh
```

If you are setting up a new Xcode project, there are a few things you will need to do, including adding the required xcframework (lib) files and include path. Note, these are all set up for you already in the Test xcodeproj files.

### Add to Project

You will need to add the xcframework files (libs) and header files (include). You will also need to add libz.tbd to the Xcode project ("General"). 

<img width="495" alt="Image" src="https://github.com/user-attachments/assets/a1f194e4-2947-48e9-aa57-01458a79f623" />

You will also need to import the `cacert.pem` certificate bundle file into your project if you plan to use HTTPS (openssl) for certificate verification.

### Sandbox Settings for macOS

For macOS builds, you will need to allow "Outgoing Connection (Client)" in the "Signing & Capabilities" of the project target "Sandbox" settings.

<img width="482" alt="Image" src="https://github.com/user-attachments/assets/cd7f5e68-bc3e-4b5c-94d6-cb44c4c2ad23" />

You will also need to add libz.tbd, libldap.tbd, CoreFoundation.framework, and SystemConfiguration.framework to the Xcode project ("General") to prevent build errors. 

<img width="482" alt="Image" src="https://github.com/user-attachments/assets/29fd3b15-f130-41cd-91d8-689a6b8b3f50" />
