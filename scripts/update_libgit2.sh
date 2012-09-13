set -e

cd "libgit2"

LIBGIT2_BRANCH="development"

git checkout "${LIBGIT2_BRANCH}"
git pull

if [ -d "build" ]; then
    rm -rf "build"
fi

mkdir build
cd build

cmake -DBUILD_SHARED_LIBS:BOOL=OFF -DBUILD_TESTS:BOOL=OFF -DTHREADSAFE:BOOL=ON ..
cmake --build .

product="libgit2.a"
install_path="../../${product}"
if [ "${product}" -nt "${install_path}" ]; then
    cp -v "${product}" "${install_path}"
fi

echo "libgit2 has been updated."
