# Objective Git - libgit2 wrapper for Objective-C
Objective Git provides Objective-C bindings to the libgit2 linkable C Git library.
It has been implemented as a framework right now. This is a good reference for
[setting up frameworks in xcode][setup]
This library follows the [rugged] API as close
as possible while trying to maintain a native objective-c feel.

[setup]: http://atastypixel.com/blog/creating-applications-in-xcode-using-frameworks
[rugged]: https://github.com/libgit2/rugged

## Unit Testing
Unit testing in being done using [GHUnit][ghunit].
We are using both the mac and iOS unit testing frameworks. The one minor
inconvenience to be aware of is that xcode doesn't like switching between
the mac test target and the iOS test target. You generally have to close
and reopen the project to move from iOS testing back to mac testing.

[ghunit]: https://github.com/gabriel/gh-unit

## libgit2
[libgit2] is included as a [submodule] of Objective Git. After cloning Objective Git,
chances are that you will want to also grab its submodules, e.g. as follows:

    $ git submodule init
    $ git submodule update

[libgit2]: https://github.com/libgit2/libgit2
[submodule]: http://book.git-scm.com/5_submodules.html

## Inclusion in Mac OS X projects

It is simple enough to add the ObjectiveGit framework to a desktop application project. An example of this is the [CommitViewer] example on GitHub. In summary:

1. Drag the ObjectiveGit.xcodeproj file into the project navigator
2. Add the ObjectiveGit framework as a target dependency of your application
3. Link your application with the ObjectiveGit framework.
4. Add a new Copy Files build phase, set the destination to Frameworks and and the ObjectiveGit framework to that - this will package the framework with your application as an embedded private framework.
5. Don't forget to `#import <ObjectiveGit/ObjectiveGit.h>` as you would with any other framework.


[CommitViewer]: https://github.com/Abizern/CommitViewer

## Inclusion in iOS projects

Inclusion of Objective Git in iOS projects is somewhat cumbersome on account of iOS
not allowing third-party dynamic frameworks. A work-around for this is as follows:

1. Drag the ObjectiveGitFramework.xcodeproj file into the Project Navigator.
2. Add ObjectiveGit-iOS as a target dependency of your application.
3. Link your application to `libObjectiveGit-iOS.a` library
4. Build Settings - Always Search User Paths - set to YES
5. Build Settings - User Header Search Paths
5.1. Add $(BUILT_PRODUCTS_DIR)/usr/local/include
5.2. Add $(SRCROOT)../Libs/objective-git/libgit2/include

## Todo

## Contributing
Fork libgit2/objective-git on GitHub, make it awesomer (preferably in a branch named
for the topic), send a pull request.

## Contributers
You can see all the amazing people contributing to this project
[here](https://github.com/libgit2/objective-git/contributors).

## License
MIT. See LICENSE file.

