#!/bin/sh

SCRIPT_DIR=$(dirname "$0")
source "${SCRIPT_DIR}/xcode_functions.sh"

function setup_build_environment ()
{
    pushd . > /dev/null
    cd "$SCRIPT_DIR/.."
    ROOT_PATH="$PWD"
    popd > /dev/null

    CLANG=`/usr/bin/xcrun --find clang`
    CC="${CLANG}"
    CPP="${CLANG} -E"
    DEVELOPER="/Applications/Xcode.app/Contents/Developer"
    # We need to clear this so that cmake doesn't have a conniption
    MACOSX_DEPLOYMENT_TARGET=""

    XCODE_MAJOR_VERSION=$(xcode_major_version)
    
    CAN_BUILD_64BIT=""

    # If IPHONEOS_DEPLOYMENT_TARGET has not been specified
    # setup reasonable defaults to allow running of a build script
    # directly (ie not from an Xcode proj)
    if [ "${XCODE_MAJOR_VERSION}" -ge "5" ]
    then
        SDKVERSION="7.0"
        if [ -z "${IPHONEOS_DEPLOYMENT_TARGET}" ]
        then
            IPHONEOS_DEPLOYMENT_TARGET=${SDKVERSION}
        fi
        # Determine if we can be building 64-bit binaries
        if [ `echo ${IPHONEOS_DEPLOYMENT_TARGET} '>=' 6.0 | bc -l` == "1" ]
        then
            CAN_BUILD_64BIT="1"
        fi
    else
        SDKVERSION="6.1"
        if [ -z "${IPHONEOS_DEPLOYMENT_TARGET}" ]
        then
            IPHONEOS_DEPLOYMENT_TARGET="5.0"
        fi
    fi

    # If ARCHS has not been specified
    # setup reasonable defaults to allow running of a build script
    # directly (ie not from an Xcode proj)
    if [ -z "${ARCHS}" ]
    then
        ARCHS="i386 armv7 armv7s"
        if [ -n "${CAN_BUILD_64BIT}" ]
        then
            # For some stupid reason cmake needs simulator builds to
            # be first
            ARCHS="x86_64 ${ARCHS} arm64"
        fi
    fi
    if [ `expr "${ARCHS}" : '.*i386.*'` == "0" ]
    then
        ARCHS="i386 ${ARCHS}"
    fi
    if [ -n "${CAN_BUILD_64BIT}" ] && [ `expr "${ARCHS}" : '.*x86_64.*'` == "0" ]
    then
        ARCHS="x86_64 ${ARCHS}"
    fi
}

function build_all_archs ()
{
    setup_build_environment
    
    local setup=$1
    local build_arch=$2
    local finish_build=$3

    # run the prepare function
    eval $setup

    echo "Building for ${ARCHS}"

    for ARCH in ${ARCHS}
    do
        if [ "${ARCH}" == "i386" ] || [ "${ARCH}" == "x86_64" ]
        then
            PLATFORM="iphonesimulator"
        else
            PLATFORM="iphoneos"
        fi

        if [ "${ARCH}" == "arm64" ]
        then
            HOST="aarch64-apple-darwin"
        else
            HOST="${ARCH}-apple-darwin"
        fi

        echo "Building ${LIBRARY_NAME} for ${PLATFORM} ${SDKVERSION} ${ARCH}"
        echo "Please stand by..."
        SDKNAME="${PLATFORM}${SDKVERSION}"
        SDKROOT="$(xcrun --sdk ${SDKNAME} --show-sdk-path)"

        # run the per arch build command
        eval $build_arch
    done

    # finish the build (usually lipo)
    eval $finish_build
}

