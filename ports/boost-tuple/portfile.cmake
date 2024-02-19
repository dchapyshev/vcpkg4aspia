# Automatically generated by scripts/boost/generate-ports.ps1

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO boostorg/tuple
    REF boost-${VERSION}
    SHA512 3c6bd4bf726fef59256a59f6b62e64fb3f5da4749a5a4ada28c2515f3f9307cc9473ce76fe17ceab7b5f60a11da441e9d21136b5277c655aefdc852b688277ff
    HEAD_REF master
)

include(${CURRENT_INSTALLED_DIR}/share/boost-vcpkg-helpers/boost-modular-headers.cmake)
boost_modular_headers(SOURCE_PATH ${SOURCE_PATH})
