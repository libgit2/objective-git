# ObjectiveGit

ObjectiveGit provides Cocoa bindings to the
[libgit2](https://github.com/libgit2/libgit2) library.

Not all libgit2 features are available yet. If you run across something missing,
please consider [contributing a pull request](#contributing)!

## Getting Started

To start building the framework, you must install the required dependencies, 
[xctool](https://github.com/facebook/xctool) and 
[cmake](https://github.com/Kitware/CMake). We recommend using 
[Homebrew](http://brew.sh) to install these two tools. 

Once you have the dependencies you should clone this repository and then run
`script/bootstrap`. This will automatically pull down and install any other
dependencies.

Note that the `bootstrap` script automatically installs some libraries that
ObjectiveGit relies upon, using Homebrew. If you want this behavior, please 
make sure you have Homebrew installed.

To develop ObjectiveGit on its own, open the `ObjectiveGitFramework.xcworkspace` file.

## Importing ObjectiveGit on OS X

It is simple enough to add the ObjectiveGit framework to a desktop application
project. An example of this is the
[CommitViewer](https://github.com/Abizern/CommitViewer) example on GitHub. In summary:

1. Drag the `ObjectiveGitFramework.xcodeproj` file into the project navigator.
1. Add the ObjectiveGit framework as a target dependency of your application.
1. Link your application with `ObjectiveGit.framework`.
1. Add a new "Copy Files" build phase, set the destination to "Frameworks" and
   add `ObjectiveGit.framework` to that. This will package the framework with
   your application as an embedded private framework.
1. Set the “Header Search Paths” (`HEADER_SEARCH_PATHS`) build setting to the
   correct path for the libgit2 headers in your project. For example, if you
   added the submodule to your project as `External/ObjectiveGit`, you would
   set this build setting to `External/ObjectiveGit/External/libgit2/include`.
   If you see build errors saying that `git2/filter.h` cannot be found, then
   double-check that you set this setting correctly.
1. Don't forget to `#import <ObjectiveGit/ObjectiveGit.h>` as you would with any
   other framework.

## Importing ObjectiveGit on iOS

Getting started is slightly more difficult on iOS because third-party frameworks
are not officially supported. ObjectiveGit offers a static library instead. An example
of this is the [ObjectiveGit iOS Example](https://github.com/Raekye/ObjectiveGit-iOS-Example)
on GitHub. In summary:

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

Fork the repository on GitHub, make it awesomer (preferably in a branch named
for the topic), send a pull request.

All contributions should match GitHub's [Objective-C coding
conventions](https://github.com/github/objective-c-conventions).

You can see all the amazing people that have contributed to this project
[here](https://github.com/libgit2/objective-git/contributors).

## License

ObjectiveGit is released under the MIT license. See
the [LICENSE](LICENSE) file.
