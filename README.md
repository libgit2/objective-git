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
* Network: clone, fetch, push, pull (in progress #464)
* Transports: HTTP, HTTPS, SSH, local filesystem

Not all libgit2 features are available, but if you run across something missing, please consider [contributing a pull request](#contributing)!

Many classes in the ObjectiveGit API wrap a C struct from libgit2 and expose the underlying data and operations using Cocoa idioms. The underlying libgit2 types are prefixed with `git_` and are often accessible via a property so that your application can take advantage of the libgit2 API directly.

The ObjectiveGit API makes extensive use of the Cocoa NSError pattern. The public API is also decorated with nullability attributes so that you will get compile-time feedback of whether nil is allowed or not. This also makes the framework much nicer to use in Swift.

## Getting Started

### Xcode

ObjectiveGit requires Xcode 6.3 or greater to build the framework and run unit tests. Projects that must use an older version of Xcode can use 
[Carthage](#carthage) to install pre-built binaries
or download them [manually](#manually).

### Other Tools

To start building the framework, you must install the required dependencies, 
[xctool](https://github.com/facebook/xctool) and 
[cmake](https://github.com/Kitware/CMake). We recommend using 
[Homebrew](http://brew.sh) to install these tools. 

Once you have the dependencies you should clone this repository and then run [`script/bootstrap`](script/bootstrap). This will automatically pull down and install any other
dependencies.

Note that the `bootstrap` script automatically installs some libraries that ObjectiveGit relies upon, using Homebrew. If you not want to use Homebrew, you will need to ensure these dependent libraries and their headers are installed where the build scripts [expect them to be](https://github.com/libgit2/objective-git/blob/master/script/bootstrap#L80-L99).

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

  ![Embedded Binaries](http://imgur.com/W9EVyIX.png)

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

The different instructions for iOS works around an [App Store submission bug](http://www.openradar.me/radar?id=6409498411401216) triggered by universal binaries.


### Copying debug symbols for debugging and crash reporting

1. On your application target's "Build Phases" settings tab, click the "+" icon and choose "New Copy Files Phase".
2. Click the “Destination” drop-down menu and select "Products Directory".
3. For each framework you’re using, drag and drop its corresponding dSYM file.


## Manual

1. Download the latest `ObjectiveGit.framework.zip` from [releases](https://github.com/libgit2/objective-git/releases).
1. Unzip the file.
1. Follow the Carthage instructions above starting at Step #3.


## Subproject

### OS X

Example: [CommitViewer](https://github.com/Abizern/CommitViewer)

1. Drag the `ObjectiveGitFramework.xcodeproj` file into the Project Navigator.
1. Add the ObjectiveGit framework as a target dependency of your application.
1. Link your application with `ObjectiveGit.framework`.
1. Add a new "Copy Files" build phase, set the destination to "Frameworks" and add `ObjectiveGit.framework` to that. This will package the framework with your application as an embedded private framework.
1. Set the “Header Search Paths” (`HEADER_SEARCH_PATHS`) build setting to the correct path for the libgit2 headers in your project. For example, if you added the submodule to your project as `External/ObjectiveGit`, you would set this build setting to `External/ObjectiveGit/External/libgit2/include`. If you see build errors saying that `git2/filter.h` cannot be found, then double-check that you set this setting correctly.
1. Don't forget to `#import <ObjectiveGit/ObjectiveGit.h>` as you would with any other framework.

### iOS

Example: [ObjectiveGit iOS Example](https://github.com/Raekye/ObjectiveGit-iOS-Example)

Getting started is slightly more difficult on iOS because third-party frameworks are not officially supported. ObjectiveGit offers a static library instead. In summary:

1. Drag `ObjectiveGitFramework.xcodeproj` into the Project Navigator.
1. Add `ObjectiveGit-iOS` as a target dependency of your application.
1. Link your application to `libObjectiveGit-iOS.a`, `libz.dylib`, and `libiconv.dylib`.
1. In your target's build settings:
    1. Set "Always Search User Paths" to `YES`
    1. Add `$(BUILT_PRODUCTS_DIR)/usr/local/include` and
       `PATH/TO/OBJECTIVE-GIT/External/libgit2/include` to the "User Header
       Search Paths"
    1. Add `-all_load` to the "Other Linker Flags"


## Contributing

Fork the repository on GitHub, make it awesomer (preferably in a branch named for the topic), send a pull request.

All contributions should match GitHub's [Objective-C coding
conventions](https://github.com/github/objective-c-conventions).

You can see all the amazing people that have contributed to this project
[here](https://github.com/libgit2/objective-git/contributors).

## License

ObjectiveGit is released under the MIT license. See
the [LICENSE](LICENSE) file.
