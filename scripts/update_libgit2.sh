set -e

if [ "libgit2.a" -nt "libgit2" ]
then
    echo "No update needed."
    exit 0
fi

cd "libgit2"

if [ -d "build" ]; then
    rm -rf "build"
fi

mkdir build
cd build

cmake -DBUILD_SHARED_LIBS:BOOL=OFF -DBUILD_CLAR:BOOL=OFF -DTHREADSAFE:BOOL=ON ..
cmake --build .

product="libgit2.a"
install_path="../../${product}"
if [ "${product}" -nt "${install_path}" ]; then
    cp -v "${product}" "${install_path}"
fi

echo "libgit2 has been updated."
