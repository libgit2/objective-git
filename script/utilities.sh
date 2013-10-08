#!/bin/sh

function xcode_major_version () {
  local XCODE_VERSION=`/usr/bin/xcodebuild -version | head -n 1 | awk '{ print $2 }'`

  local XCODE_MAJOR_VERSION=`echo $XCODE_VERSION | awk -F '.' '{ print $1 }'`

  echo $XCODE_MAJOR_VERSION
}
