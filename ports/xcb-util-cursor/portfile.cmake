if(NOT X_VCPKG_FORCE_VCPKG_X_LIBRARIES AND NOT VCPKG_TARGET_IS_WINDOWS)
    message(STATUS "Utils and libraries provided by '${PORT}' should be provided by your system! Install the required packages or force vcpkg libraries by setting X_VCPKG_FORCE_VCPKG_X_LIBRARIES in your triplet!")
    set(VCPKG_POLICY_EMPTY_PACKAGE enabled)
else()

vcpkg_from_gitlab(
    GITLAB_URL https://gitlab.freedesktop.org/xorg
    OUT_SOURCE_PATH SOURCE_PATH
    REPO lib/libxcb-cursor
    REF  7b0fa99aa13084a9bf7be4180066f6a74b0adef1 #v 0.1.6
    SHA512 326182d26ddeb97d7872ab4ac7ebbb30c3d3231b7a59eb914c096d2f23906e284cfe097b3a92f8ae33102df165472e909761afa6ac1dad29d0f84ed60b208533
    HEAD_REF master
)
file(TOUCH "${SOURCE_PATH}/m4/dummy")
set(ENV{ACLOCAL} "aclocal -I \"${CURRENT_INSTALLED_DIR}/share/xorg/aclocal/\"")

# The default cursor theme search path is derived from ${datadir}, which under vcpkg points inside the
# install prefix - a path that does not exist on target machines, so no cursor theme is ever found and
# applications fall back to the tiny non-scalable X core font cursors. Bake the standard system path in.
vcpkg_make_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    AUTORECONF
    OPTIONS
        "--with-cursorpath=~/.local/share/icons:~/.icons:/usr/local/share/icons:/usr/share/icons:/usr/share/pixmaps"
)

vcpkg_make_install()
vcpkg_fixup_pkgconfig()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")

file(INSTALL "${SOURCE_PATH}/COPYING" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)
endif()
