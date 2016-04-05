# ObjectiveGit

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Build Status](https://travis-ci.org/libgit2/objective-git.svg?branch=master)](https://travis-ci.org/libgit2/objective-git)

ObjectiveGit provides Cocoa bindings to the
[libgit2](https://github.com/libgit2/libgit2) library, packaged as a dynamic framework for OS X and iOS 8 or better.

## Features

A brief summary of the available functionality:

* Read: log, diff, blame, reflog, status
* Write: init, checkout, commit, branch, tag, reset
* Internals: configuration, tree, blob, object database
* Network: clone, fetch, push, pull
* Transports: HTTP, HTTPS, SSH, local filesystem

Not all libgit2 features are available, but if you run across something missing, please consider [contributing a pull request](#contributing)!

Many classes in the ObjectiveGit API wrap a C struct from libgit2 and expose the underlying data and operations using Cocoa idioms. The underlying libgit2 types are prefixed with `git_` and are often accessible via a property so that your application can take advantage of the [libgit2 API](https://libgit2.github.com/libgit2/#HEAD) directly.

The ObjectiveGit API makes extensive use of the Cocoa NSError pattern. The public API is also decorated with nullability attributes so that you will get compile-time feedback of whether nil is allowed or not. This also makes the framework much nicer to use in Swift.

## Getting Started

### Xcode

ObjectiveGit requires Xcode 7 or greater to build the framework and run unit tests. Projects that must use an older version of Xcode can use
[Carthage](#carthage) to install pre-built binaries
or download them [manually](#manually).

### Other Tools

Simply run the [`script/bootstrap`](script/bootstrap) script to automatically install
dependencies needed to start building the framework. This script uses
[Homebrew](http://brew.sh) to install these tools. If your Mac does not have
Homebrew, you will need to install the following manually:

- [cmake](https://github.com/Kitware/CMake)
- libtool
- autoconf
- automake
- pkg-config
- libssh2
  - symlinks:  lib/libssh2.a include/libssh2.h include/libssh2_sftp.h include/libssh2_publickey.h

To develop ObjectiveGit on its own, open the `ObjectiveGitFramework.xcworkspace` file.

# Installation

There are three ways of including ObjectiveGit in a project:

1. [Carthage](#carthage) <-- recommended
1. [Manual](#manual)
1. [Subproject](#subproject)


## Carthage

1. Add ObjectiveGit to your [`Cartfile`](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#cartfile).

  ```
  github "libgit2/objective-git"
  ```

1. Run `carthage update`.
1. **Mac targets**
  * On your application targets' "General" settings tab, in the "Embedded Binaries" section, drag and drop the `ObjectiveGit.framework` from the [`Carthage/Build/Mac`](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#carthagebuild) folder on disk.

  ![Embedded Binaries](http://i.imgur.com/W9EVyIX.png)

1. **iOS targets**
  * On your application targets' "General" settings tab, in the "Linked Frameworks and Libraries" section, drag and drop the `ObjectiveGit.framework` from the [`Carthage/Build/iOS`](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#carthagebuild) folder on disk.
  ![Linked Frameworks](http://i.imgur.com/y4caRw0.png)

  * On your application targets' "Build Phases" settings tab, click the “+” icon and choose “New Run Script Phase”. Create a Run Script with the following contents:

  ```
  /usr/local/bin/carthage copy-frameworks
  ```

  and add the paths to the frameworks you want to use under “Input Files”, e.g.:

  ```
  $(SRCROOT)/Carthage/Build/iOS/ObjectiveGit.framework
  ```

  ![Carthage Copy Frameworks](http://i.imgur.com/zXai6rb.png)

1. Commit the [`Cartfile.resolved`](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#cartfileresolved)

2. Under “Build Settings”, add the following to “Header Search Paths”: `$(SRCROOT)/Carthage/Build/iOS/ObjectiveGit.framework/Headers/` to avoid [`git2/filter.h file not found` errors](https://github.com/libgit2/objective-git/issues/441).

The different instructions for iOS works around an [App Store submission bug](http://www.openradar.me/radar?id=6409498411401216) triggered by universal binaries.


### Copying debug symbols for debugging and crash reporting

_dSYM files are not currently included in the GitHub release zip files. You will need to pass **--no-use-binaries** to carthage in order to build locally and generate the dSYM files alongside the framework._

1. On your application target's "Build Phases" settings tab, click the "+" icon and choose "New Copy Files Phase".
2. Click the “Destination” drop-down menu and select "Products Directory".
3. Drag and drop the `ObjectiveGit.framework.dSYM` file from `Carthage/Build/[platform]` into the list.

![Copy dSYM Files](http://i.imgur.com/WKJdHHQ.png)


## Manual

1. Download the latest `ObjectiveGit.framework.zip` from [releases](https://github.com/libgit2/objective-git/releases).
1. Unzip the file.
1. Follow the Carthage instructions #3 or #4, depending on platform.

Note that the iOS framework we release is a "fat" framework containing slices for both the iOS Simulator and devices. This makes it easy to get started with your iOS project. However, Apple does not currently allow apps containing frameworks with simulator slices to be submitted to the app store. Carthage (above) already has a solution for this. If you're looking to roll your own, take a look at Realm's [strip frameworks script](https://github.com/realm/realm-cocoa/blob/master/scripts/strip-frameworks.sh).


## Subproject

### Examples

* OS X: [CommitViewer](https://github.com/Abizern/CommitViewer)
* iOS: [ObjectiveGit iOS Example](https://github.com/Raekye/ObjectiveGit-iOS-Example)

1. Add ObjectiveGit as a submodule to your project:

  ```
  git submodule add https://github.com/libgit2/objective-git.git External/ObjectiveGit
  ```

1. Run `script/bootstrap`.
1. Drag the `ObjectiveGitFramework.xcodeproj` file into the Project Navigator pane of your project.
1. Add `ObjectiveGit-Mac` or `ObjectiveGit-iOS` as a target dependency of your application, depending on platform.
1. Link your application with `ObjectiveGit.framework`.
1. Set the “Header Search Paths” (`HEADER_SEARCH_PATHS`) build setting to the correct path for the libgit2 headers in your project. For example, if you added the submodule to your project as `External/ObjectiveGit`, you would set this build setting to `External/ObjectiveGit/External/libgit2/include`. If you see build errors saying that `git2/filter.h` cannot be found, then double-check that you set this setting correctly.
1. Add a new "Copy Files" build phase, set the destination to "Frameworks" and add `ObjectiveGit.framework` to the list. This will package the framework with your application as an embedded private framework.
  *  It's hard to tell the difference between the platforms, but the Mac framework is in `build/Debug` whereas the iOS framework is in `build/Debug-iphoneos`
1. Don't forget to `#import <ObjectiveGit/ObjectiveGit.h>` or `@import ObjectiveGit;` as you would with any other framework.



## Contributing

1. Fork this repository
1. Make it awesomer (preferably in a branch named for the topic)
1. Send a pull request

All contributions should match GitHub's [Objective-C coding
conventions](https://github.com/github/objective-c-style-guide).

You can see all the amazing people that have contributed to this project
[here](https://github.com/libgit2/objective-git/graphs/contributors).


## License

ObjectiveGit is released under the MIT license. See
the [LICENSE](LICENSE) file.
