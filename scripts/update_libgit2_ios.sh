set -e

if [ "libgit2-ios.a" -nt "libgit2" ]
then
    echo "No update needed."
    exit 0
fi

ios_version="6.1";

cd "libgit2"

# armv7 build

if [ -d "build" ]; then
    rm -rf "build"
fi

mkdir build
cd build

cmake -DCMAKE_C_COMPILER_WORKS:BOOL=ON \
      -DBUILD_SHARED_LIBS:BOOL=OFF \
      -DCMAKE_C_COMPILER=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/llvm-gcc-4.2/bin/llvm-gcc-4.2 \
      -DOPENSSL_SSL_LIBRARY:FILEPATH= \
      -DOPENSSL_CRYPTO_LIBRARY:FILEPATH= \
      -DCMAKE_OSX_DEPLOYMENT_TARGET:STRING= \
      -DCMAKE_OSX_ARCHITECTURES:STRING="armv7;armv7s" \
      -DBUILD_CLAR:BOOL=OFF \
      -DCMAKE_OSX_SYSROOT=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS${ios_version}.sdk/ \
      ..
cmake --build .

product="libgit2.a"
install_path="../../libgit2-ios-armv7.a"
if [ "${product}" -nt "${install_path}" ]; then
    cp -v "${product}" "${install_path}"
fi

cd ../

# i386 build

if [ -d "build" ]; then
    rm -rf "build"
fi

mkdir build
cd build

cmake -DCMAKE_C_COMPILER_WORKS:BOOL=ON \
      -DBUILD_SHARED_LIBS:BOOL=OFF \
      -DCMAKE_C_COMPILER=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/llvm-gcc-4.2/bin/llvm-gcc-4.2 \
      -DOPENSSL_SSL_LIBRARY:FILEPATH= \
      -DOPENSSL_CRYPTO_LIBRARY:FILEPATH= \
      -DCMAKE_OSX_DEPLOYMENT_TARGET:STRING= \
      -DCMAKE_OSX_ARCHITECTURES:STRING=i386 \
      -DBUILD_CLAR:BOOL=OFF \
      -DCMAKE_OSX_SYSROOT=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator${ios_version}.sdk/ \
      ..
cmake --build .

product="libgit2.a"
install_path="../../libgit2-ios-i386.a"
if [ "${product}" -nt "${install_path}" ]; then
    cp -v "${product}" "${install_path}"
fi

cd ../../

# link static libraries
libtool -static libgit2-ios-armv7.a libgit2-ios-i386.a -o libgit2-ios.a

# cleanup
rm libgit2-ios-armv7.a
rm libgit2-ios-i386.a

echo "libgit2-ios has been updated."
