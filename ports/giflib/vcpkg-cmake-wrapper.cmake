find_path(GIF_INCLUDE_DIR gif_lib.h PATH_SUFFIXES include PATHS "${_VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}" NO_DEFAULT_PATH)

_find_package(${ARGS})
