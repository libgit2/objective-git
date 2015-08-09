#!/bin/bash

# Returns the version # of xcodebuild
# eg. (4.6.3, 5.0, 5.0.1)
function xcode_version ()
{
    /usr/bin/xcodebuild -version 2> /dev/null | head -n 1 | awk '{ print $2 }'
}

# Returns the major version of xcodebuild
# eg. (4, 5, 6)
function xcode_major_version ()
{
    xcode_version | awk -F '.' '{ print $1 }'
}

# Returns the latest iOS SDK version available via xcodebuild.
function ios_sdk_version ()
{
    # The grep command produces output like the following, singling out the
    # SDKVersion of just the iPhone* SDKs:
    #
    #   iPhoneOS9.0.sdk - iOS 9.0 (iphoneos9.0)
    #   SDKVersion: 9.0
    #   --
    #   iPhoneSimulator9.0.sdk - Simulator - iOS 9.0 (iphonesimulator9.0)
    #   SDKVersion: 9.0

    /usr/bin/xcodebuild -version -sdk 2> /dev/null | grep -A 1 '^iPhone' | tail -n 1 |  awk '{ print $2 }' 
}

# Returns the path to the specified iOS SDK name
function ios_sdk_path ()
{
    /usr/bin/xcodebuild -version -sdk 2> /dev/null | grep -i $1 | grep 'Path:' | awk '{ print $2 }'
}
