# Automatically generated by scripts/boost/generate-ports.ps1

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO boostorg/iterator
    REF boost-1.82.0
    SHA512 078b8f8a36788295494d9c7224f222c50a15badef143af4a0a4f7fc10ae1aecb76d656de7f5c8d7166257dcad98f2e31f38736deaab12ef60af7720258c5332b
    HEAD_REF master
)

include(${CURRENT_INSTALLED_DIR}/share/boost-vcpkg-helpers/boost-modular-headers.cmake)
boost_modular_headers(SOURCE_PATH ${SOURCE_PATH})
