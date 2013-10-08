#!/bin/sh

# Returns the version # of xcodebuild
# eg. (4.6.3, 5.0, 5.0.1)
function xcode_version ()
{
    local XCODE_VERSION=`/usr/bin/xcodebuild -version | head -n 1 | awk '{ print $2 }'`
    echo $XCODE_VERSION
}

# Returns the major version of xcodebuild
# eg. (4, 5, 6)
function xcode_major_version ()
{
    local XCODE_MAJOR_VERSION=`echo $(xcode_version) | awk -F '.' '{ print $1 }'`

    echo $XCODE_MAJOR_VERSION
}
