#!/bin/bash

# Returns the version # of xcodebuild
# eg. (4.6.3, 5.0, 5.0.1)
function xcode_version ()
{
    /usr/bin/xcodebuild -version | head -n 1 | awk '{ print $2 }'
}

# Returns the major version of xcodebuild
# eg. (4, 5, 6)
function xcode_major_version ()
{
    xcode_version | awk -F '.' '{ print $1 }'
}

# Returns the latest iOS SDK version available
# via xcodebuild
function ios_sdk_version ()
{
    # This relies on the fact that the latest iPhone SDK
    # is the last thing listed before the Xcode version.
    /usr/bin/xcodebuild -version -sdk | tail -n 4 | head -n 1 | awk '{ print $2 }'
}

# Returns the path to the specified iOS SDK name
function ios_sdk_path ()
{
    /usr/bin/xcodebuild -version -sdk | grep -i $1 | grep 'Path:' | awk '{ print $2 }'
}
