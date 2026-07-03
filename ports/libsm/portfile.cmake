if(NOT X_VCPKG_FORCE_VCPKG_X_LIBRARIES AND NOT VCPKG_TARGET_IS_WINDOWS)
    message(STATUS "Utils and libraries provided by '${PORT}' should be provided by your system! Install the required packages or force vcpkg libraries by setting X_VCPKG_FORCE_VCPKG_X_LIBRARIES in your triplet!")
    set(VCPKG_POLICY_EMPTY_PACKAGE enabled)
    return()
endif()

vcpkg_download_distfile(
    LIBSM_ARCHIVE
    URLS "https://www.x.org/releases/individual/lib/libSM-${VERSION}.tar.xz"
    FILENAME "libSM-${VERSION}.tar.xz"
    SHA512 e544a1dc49a03390f76af35837bfd01f749b806d88d3ee806f20311c47ff53d0aeea4744feb875958031b17d50b57a89dcc41d81241c09333c88b268c44653a7
)

vcpkg_extract_source_archive(
    SOURCE_PATH
    ARCHIVE "${LIBSM_ARCHIVE}"
    PATCHES
        msvc.patch
)

set(ENV{ACLOCAL} "aclocal -I \"${CURRENT_INSTALLED_DIR}/share/xorg/aclocal/\"")

# Build without libuuid: it only supplies the SM client-id seed, and linking it would add a runtime
# dependency on the system libuuid (and undefined uuid_* at the final static link, since CMake's FindX11
# does not chain uuid onto X11::SM). Without it libSM falls back to a host/time/pid based id, which is
# fine for our use.
vcpkg_make_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    AUTORECONF
    OPTIONS
        --without-libuuid
)

vcpkg_make_install()
vcpkg_fixup_pkgconfig()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/COPYING")
