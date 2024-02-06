[Russian/Русский](README_RUS.md) 

# Description
Rutoken Technologies is an application for demonstrating the capabilities of the Rutoken ECP line on mobile devices based on iOS or iPadOS 16.2 and newer.
It contains two sections:
* Certification Authority— designed to demonstrate the capabilities of the test certification authority. Here you can generate a key pair and issue a test certificate on a mobile device. Created objects can be used in the Bank section.
* Bank — designed to demonstrate the scenarios of work with Rutoken devices in bank apps. Here you can sign a test payment document, check the validity of the electronic signature of incoming documents, encrypt and decrypt a bank document.

# Requirements
The application is built with iOS SDK 16.2 and newer and launches on iOS ans iPadOS devices with version 16.2 and newer.
External dependencies can be found in the [RutokenSDK](http://www.rutoken.ru/developers/sdk/)

Needed files and frameworks:
•  openssl/bin/3.0/openssl-3.0/openssl-tool-3.0/macos-x86_64+arm64/*
•  openssl/bin/3.0/rtengine-3.0/ios+iossim+macos-x86_64+arm64-xcframework/rtengine.xcframework

 **Pay attention: this is an instruction on how to setup the Rutoken Technologies application. Read more about the features and embedding tokens into your apps in [features of embedding Rutoken ECP line with NFC into your own applications](https://dev.rutoken.ru/pages/viewpage.action?pageId=81527019)**.

# Preliminary actions
To work in the Bank section you must have a key pair and a certificate on your Rutoken ECP device.
If your device doesn't contain a key pair and a certificate, you can create them in the Certification authority section for testing purposes. Or follow these steps on your desktop computer:
1.  Download and install [Rutoken Plugin](https://www.rutoken.ru/products/all/rutoken-plugin/) on your computer.
2.  Restart the browser to finish plugin installation.
3.  Open [Rutoken registration center](https://ra.rutoken.ru/) website via browser.
4.  Connect your Rutoken ECP device to the computer.
5.  Make sure that the website has detected your device.
6.  Follow the instructions on the website and create a key pair and a certificate.
7.  Make sure that the website has detected the created key pair and the certificate on your device.
8.  Disconnect your Rutoken ECP device from the computer and use it with iPhone or iPad.

# Generatation of Key Pairs & certificates for working with Rutoken Tech
To work in the Bank and the CA sections the project has to contain its own files of keys and certificates that are located in `Rutoken Tech/Credentials`. The repository already contains pre-generated files but you can create your own using the instruction below:
1.  Put rtengine.xcframework in directory `prepareCredentials` placed in the root of project;
2.  Put directory with OpenSSL binary files (`macos-x86_64+arm64`) in directory `prepareCredentials` placed in the root of project;
3.  Set path of rtengine binary in openssl.cnf placed in directory `prepareCredentials`:
```
openssl_conf = openssl_def

[ openssl_def ]
    engines = engine_section

[ engine_section ]
    rtengine = gost_section

[ gost_section ]
    dynamic_path = /path/to/rtengine.xcframework/macos-arm64_x86_64/rtengine.framework/rtengine
```
4.  Run `generateCredentials.sh`.

# Restrictions
This application may be launched only on physical Apple devices, and can not be launched on their emulators.

# Licenses
The project software code is distributed under [Simplified BSD License](LICENSE), rutoken-tech-ios directory contains copyright objects and is distributed under the [commercial license of Aktiv-Soft JSC](https://download.rutoken.ru/License_Agreement.pdf).
