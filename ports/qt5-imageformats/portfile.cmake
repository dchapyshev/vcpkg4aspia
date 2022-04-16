set(VCPKG_POLICY_EMPTY_INCLUDE_FOLDER enabled)
include(${CURRENT_INSTALLED_DIR}/share/qt5/qt_port_functions.cmake)


list(APPEND CORE_OPTIONS
    -no-tiff
    -no-webp
    -no-jasper 
    -no-mng # must be explicitly disabled to not automatically pick up mng
    -verbose)

# Depends on opengl in default build but might depend on giflib, libjpeg-turbo, zlib, libpng, tiff, freeglut (!osx), sdl1 (windows) 
# which would require extra libraries to be linked e.g. giflib freeglut sdl1 other ones are already linked

set(OPT_REL "")
set(OPT_DBG "")

qt_submodule_installation(BUILD_OPTIONS ${CORE_OPTIONS} BUILD_OPTIONS_RELEASE ${OPT_REL} BUILD_OPTIONS_DEBUG ${OPT_DBG})