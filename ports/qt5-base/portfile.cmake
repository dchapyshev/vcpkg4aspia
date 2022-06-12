vcpkg_buildpath_length_warning(37)

if(VCPKG_LIBRARY_LINKAGE STREQUAL "static")
    set(QT_OPENSSL_LINK_DEFAULT ON)
else()
    set(QT_OPENSSL_LINK_DEFAULT OFF)
endif()
option(QT_OPENSSL_LINK "Link against OpenSSL at compile-time." ${QT_OPENSSL_LINK_DEFAULT})

if (VCPKG_TARGET_IS_LINUX)
    message(WARNING "qt5-base currently requires some packages from the system package manager, see https://doc.qt.io/qt-5/linux-requirements.html")
    message(WARNING 
[[
qt5-base for qt5-x11extras requires several libraries from the system package manager. Please refer to
  https://github.com/microsoft/vcpkg/blob/master/scripts/azure-pipelines/linux/provision-image.sh
  for a complete list of them.
]]
    )
endif()

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR})
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/cmake)

if("latest" IN_LIST FEATURES) # latest = core currently
    set(QT_BUILD_LATEST ON)
    set(PATCHES
        patches/Qt5BasicConfig.patch
        patches/Qt5PluginTarget.patch
        patches/create_cmake.patch
        )
else()
    set(PATCHES
        patches/Qt5BasicConfig.patch
        patches/Qt5PluginTarget.patch
        patches/create_cmake.patch
    )
endif()

include(qt_port_functions)
include(configure_qt)
include(install_qt)


#########################
## Find Host and Target mkspec name for configure
include(find_qt_mkspec)
find_qt_mkspec(TARGET_MKSPEC HOST_MKSPEC HOST_TOOLS)
set(QT_PLATFORM_CONFIGURE_OPTIONS TARGET_PLATFORM ${TARGET_MKSPEC})
if(DEFINED HOST_MKSPEC)
    list(APPEND QT_PLATFORM_CONFIGURE_OPTIONS HOST_PLATFORM ${HOST_MKSPEC})
endif()
if(DEFINED HOST_TOOLS)
    list(APPEND QT_PLATFORM_CONFIGURE_OPTIONS HOST_TOOLS_ROOT ${HOST_TOOLS})
endif()

#########################
## Downloading Qt5-Base

qt_download_submodule(  OUT_SOURCE_PATH SOURCE_PATH
                        PATCHES
                            patches/winmain_pro.patch          #Moves qtmain to manual-link
                            patches/windows_prf.patch          #fixes the qtmain dependency due to the above move
                            patches/qt_app.patch               #Moves the target location of qt5 host apps to always install into the host dir.
                            patches/gui_configure.patch        #Patches the gui configure.json to break freetype/fontconfig autodetection because it does not include its dependencies.
                            patches/icu.patch                  #Help configure find static icu builds in vcpkg on windows
                            patches/xlib.patch                 #Patches Xlib check to actually use Pkgconfig instead of makeSpec only
                            patches/egl.patch                  #Fix egl detection logic.
                            patches/mysql_plugin_include.patch #Fix include path of mysql plugin
                            patches/mysql-configure.patch      #Fix mysql project
                            patches/cocoa.patch                #Fix missing include on macOS Monterrey, https://code.qt.io/cgit/qt/qtbase.git/commit/src/plugins/platforms/cocoa?id=dece6f5840463ae2ddf927d65eb1b3680e34a547
                            #patches/static_opengl.patch       #Use this patch if you really want to statically link angle on windows (e.g. using -opengl es2 and -static).
                                                               #Be carefull since it requires definining _GDI32_ for all dependent projects due to redefinition errors in the
                                                               #the windows supplied gl.h header and the angle gl.h otherwise.
                            # CMake fixes
                            patches/Qt5BasicConfig.patch
                            patches/Qt5PluginTarget.patch
                            patches/create_cmake.patch
                            patches/Qt5GuiConfigExtras.patch   # Patches the library search behavior for EGL since angle is not build with Qt
                            patches/limits_include.patch       # Add missing includes to build with gcc 11
                    )

# Remove vendored dependencies to ensure they are not picked up by the build
foreach(DEPENDENCY zlib freetype libjpeg libpng double-conversion sqlite pcre2)
    if(EXISTS ${SOURCE_PATH}/src/3rdparty/${DEPENDENCY})
        file(REMOVE_RECURSE ${SOURCE_PATH}/src/3rdparty/${DEPENDENCY})
    endif()
endforeach()
#file(REMOVE_RECURSE ${SOURCE_PATH}/include/QtZlib)

#########################
## Setup Configure options

# This fixes issues on machines with default codepages that are not ASCII compatible, such as some CJK encodings
set(ENV{_CL_} "/utf-8")

set(CORE_OPTIONS
    -confirm-license
    -opensource
    -ltcg
    -verbose
)

## 3rd Party Libs
list(APPEND CORE_OPTIONS
    -system-zlib
    -system-libpng
    -system-freetype
    -system-pcre
    -system-doubleconversion
    -system-sqlite
    -qt-harfbuzz
    -no-icu
    -no-angle
    -no-glib
    -no-libjpeg
    -no-feature-concurrent
    -no-feature-dtls
    -no-feature-lcdnumber
    -no-feature-movie
    -no-feature-networkdiskcache
    -no-feature-textodfwriter
    -no-feature-future
    -no-feature-ftp
    -no-feature-sharedmemory
    -no-feature-splashscreen
    -no-feature-udpsocket
    -no-feature-textmarkdownreader
    -no-feature-textmarkdownwriter
    -no-feature-imageformat_jpeg
    -no-feature-gestures
    -no-feature-sessionmanager
    -no-feature-statemachine
    -no-sql-sqlite2
    -no-sql-psql
    -no-sql-mysql
    -no-sql-odbc
    -no-sql-oci
    -no-sql-ibase
    -no-sql-db2
)

if(QT_OPENSSL_LINK)
    list(APPEND CORE_OPTIONS -openssl-linked)
endif()

find_library(ZLIB_RELEASE NAMES z zlib PATHS "${CURRENT_INSTALLED_DIR}/lib" NO_DEFAULT_PATH)
find_library(ZLIB_DEBUG NAMES z zlib zd zlibd PATHS "${CURRENT_INSTALLED_DIR}/debug/lib" NO_DEFAULT_PATH)
find_library(LIBPNG_RELEASE NAMES png16 libpng16 PATHS "${CURRENT_INSTALLED_DIR}/lib" NO_DEFAULT_PATH) #Depends on zlib
find_library(LIBPNG_DEBUG NAMES png16 png16d libpng16 libpng16d PATHS "${CURRENT_INSTALLED_DIR}/debug/lib" NO_DEFAULT_PATH)

find_library(PCRE2_RELEASE NAMES pcre2-16 pcre2-16-static PATHS "${CURRENT_INSTALLED_DIR}/lib" NO_DEFAULT_PATH)
find_library(PCRE2_DEBUG NAMES pcre2-16 pcre2-16-static pcre2-16d pcre2-16-staticd PATHS "${CURRENT_INSTALLED_DIR}/debug/lib" NO_DEFAULT_PATH)
find_library(FREETYPE_RELEASE NAMES freetype PATHS "${CURRENT_INSTALLED_DIR}/lib" NO_DEFAULT_PATH) #zlib, bzip2, libpng
find_library(FREETYPE_DEBUG NAMES freetype freetyped PATHS "${CURRENT_INSTALLED_DIR}/debug/lib" NO_DEFAULT_PATH)
find_library(DOUBLECONVERSION_RELEASE NAMES double-conversion PATHS "${CURRENT_INSTALLED_DIR}/lib" NO_DEFAULT_PATH)
find_library(DOUBLECONVERSION_DEBUG NAMES double-conversion PATHS "${CURRENT_INSTALLED_DIR}/debug/lib" NO_DEFAULT_PATH)
find_library(SQLITE_RELEASE NAMES sqlite3 PATHS "${CURRENT_INSTALLED_DIR}/lib" NO_DEFAULT_PATH) # Depends on openssl and zlib(linux)
find_library(SQLITE_DEBUG NAMES sqlite3 sqlite3d PATHS "${CURRENT_INSTALLED_DIR}/debug/lib" NO_DEFAULT_PATH)

find_library(FONTCONFIG_RELEASE NAMES fontconfig PATHS "${CURRENT_INSTALLED_DIR}/lib" NO_DEFAULT_PATH)
find_library(FONTCONFIG_DEBUG NAMES fontconfig PATHS "${CURRENT_INSTALLED_DIR}/debug/lib" NO_DEFAULT_PATH)
find_library(EXPAT_RELEASE NAMES expat PATHS "${CURRENT_INSTALLED_DIR}/lib" NO_DEFAULT_PATH)
find_library(EXPAT_DEBUG NAMES expat PATHS "${CURRENT_INSTALLED_DIR}/debug/lib" NO_DEFAULT_PATH)

#Dependent libraries
find_library(ZSTD_RELEASE NAMES zstd PATHS "${CURRENT_INSTALLED_DIR}/lib" NO_DEFAULT_PATH)
find_library(ZSTD_DEBUG NAMES zstd PATHS "${CURRENT_INSTALLED_DIR}/debug/lib" NO_DEFAULT_PATH)
find_library(BZ2_RELEASE bz2 PATHS "${CURRENT_INSTALLED_DIR}/lib" NO_DEFAULT_PATH)
find_library(BZ2_DEBUG bz2 bz2d PATHS "${CURRENT_INSTALLED_DIR}/debug/lib" NO_DEFAULT_PATH)
find_library(SSL_RELEASE ssl ssleay32 PATHS "${CURRENT_INSTALLED_DIR}/lib" NO_DEFAULT_PATH)
find_library(SSL_DEBUG ssl ssleay32 ssld ssleay32d PATHS "${CURRENT_INSTALLED_DIR}/debug/lib" NO_DEFAULT_PATH)
find_library(EAY_RELEASE libeay32 crypto libcrypto PATHS "${CURRENT_INSTALLED_DIR}/lib" NO_DEFAULT_PATH)
find_library(EAY_DEBUG libeay32 crypto libcrypto libeay32d cryptod libcryptod PATHS "${CURRENT_INSTALLED_DIR}/debug/lib" NO_DEFAULT_PATH)

set(FREETYPE_RELEASE_ALL "${FREETYPE_RELEASE} ${BZ2_RELEASE} ${LIBPNG_RELEASE} ${ZLIB_RELEASE}")
set(FREETYPE_DEBUG_ALL "${FREETYPE_DEBUG} ${BZ2_DEBUG} ${LIBPNG_DEBUG} ${ZLIB_DEBUG}")

set(RELEASE_OPTIONS
            "ZLIB_LIBS=${ZLIB_RELEASE}"
            "LIBPNG_LIBS=${LIBPNG_RELEASE} ${ZLIB_RELEASE}"
            "PCRE2_LIBS=${PCRE2_RELEASE}"
            "FREETYPE_LIBS=${FREETYPE_RELEASE_ALL}"
            "QMAKE_LIBS_PRIVATE+=${BZ2_RELEASE}"
            "QMAKE_LIBS_PRIVATE+=${LIBPNG_RELEASE}"
            "QMAKE_LIBS_PRIVATE+=${ZSTD_RELEASE}"
            )
set(DEBUG_OPTIONS
            "ZLIB_LIBS=${ZLIB_DEBUG}"
            "LIBPNG_LIBS=${LIBPNG_DEBUG} ${ZLIB_DEBUG}"
            "PCRE2_LIBS=${PCRE2_DEBUG}"
            "FREETYPE_LIBS=${FREETYPE_DEBUG_ALL}"
            "QMAKE_LIBS_PRIVATE+=${BZ2_DEBUG}"
            "QMAKE_LIBS_PRIVATE+=${LIBPNG_DEBUG}"
            "QMAKE_LIBS_PRIVATE+=${ZSTD_DEBUG}"
            )

if(VCPKG_TARGET_IS_WINDOWS)
    if(NOT ${VCPKG_LIBRARY_LINKAGE} STREQUAL "static")
        list(APPEND CORE_OPTIONS -no-opengl -no-dbus)
    else()
        list(APPEND CORE_OPTIONS -no-opengl -no-dbus)
    endif()
    list(APPEND RELEASE_OPTIONS
            "SQLITE_LIBS=${SQLITE_RELEASE}"
            "OPENSSL_LIBS=${SSL_RELEASE} ${EAY_RELEASE} ws2_32.lib secur32.lib advapi32.lib shell32.lib crypt32.lib user32.lib gdi32.lib"
        )

    list(APPEND DEBUG_OPTIONS
            "SQLITE_LIBS=${SQLITE_DEBUG}"
            "OPENSSL_LIBS=${SSL_DEBUG} ${EAY_DEBUG} ws2_32.lib secur32.lib advapi32.lib shell32.lib crypt32.lib user32.lib gdi32.lib"
        )
elseif(VCPKG_TARGET_IS_LINUX)
    list(APPEND CORE_OPTIONS -fontconfig -xcb-xlib -xcb -linuxfb)
    if (NOT EXISTS "/usr/include/GL/glu.h")
        message(FATAL_ERROR "qt5 requires libgl1-mesa-dev and libglu1-mesa-dev, please use your distribution's package manager to install them.\nExample: \"apt-get install libgl1-mesa-dev libglu1-mesa-dev\"")
    endif()
    list(APPEND RELEASE_OPTIONS
            "SQLITE_LIBS=${SQLITE_RELEASE} -ldl -lpthread"
            "OPENSSL_LIBS=${SSL_RELEASE} ${EAY_RELEASE} -ldl -lpthread"
            "FONTCONFIG_LIBS=${FONTCONFIG_RELEASE} ${FREETYPE_RELEASE} ${EXPAT_RELEASE} -luuid"
        )
    list(APPEND DEBUG_OPTIONS
            "SQLITE_LIBS=${SQLITE_DEBUG} -ldl -lpthread"
            "OPENSSL_LIBS=${SSL_DEBUG} ${EAY_DEBUG} -ldl -lpthread"
            "FONTCONFIG_LIBS=${FONTCONFIG_DEBUG} ${FREETYPE_DEBUG} ${EXPAT_DEBUG} -luuid"
        )
elseif(VCPKG_TARGET_IS_OSX)
    list(APPEND CORE_OPTIONS -fontconfig)
    if("${VCPKG_TARGET_ARCHITECTURE}" MATCHES "arm64")
        FILE(READ "${SOURCE_PATH}/mkspecs/common/macx.conf" _tmp_contents)
        string(REPLACE "QMAKE_APPLE_DEVICE_ARCHS = x86_64" "QMAKE_APPLE_DEVICE_ARCHS = arm64" _tmp_contents ${_tmp_contents})
        FILE(WRITE "${SOURCE_PATH}/mkspecs/common/macx.conf" ${_tmp_contents})
    endif()
    if(DEFINED VCPKG_OSX_DEPLOYMENT_TARGET)
        set(ENV{QMAKE_MACOSX_DEPLOYMENT_TARGET} ${VCPKG_OSX_DEPLOYMENT_TARGET})
    else()
        execute_process(COMMAND xcrun --show-sdk-version
                            OUTPUT_FILE OSX_SDK_VER.txt
                            WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR})
        FILE(STRINGS "${CURRENT_BUILDTREES_DIR}/OSX_SDK_VER.txt" OSX_SDK_VERSION REGEX "^[0-9][0-9]\.[0-9][0-9]*")
        message(STATUS "Detected OSX SDK Version: ${OSX_SDK_VERSION}")
        string(REGEX MATCH "^[0-9][0-9]\.[0-9][0-9]*" OSX_SDK_VERSION ${OSX_SDK_VERSION})
        message(STATUS "Major.Minor OSX SDK Version: ${OSX_SDK_VERSION}")

        execute_process(COMMAND sw_vers -productVersion
                            OUTPUT_FILE OSX_SYS_VER.txt
                            WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR})
        FILE(STRINGS "${CURRENT_BUILDTREES_DIR}/OSX_SYS_VER.txt" VCPKG_OSX_DEPLOYMENT_TARGET REGEX "^[0-9][0-9]\.[0-9][0-9]*")
        message(STATUS "Detected OSX system Version: ${VCPKG_OSX_DEPLOYMENT_TARGET}")
        string(REGEX MATCH "^[0-9][0-9]\.[0-9][0-9]*" VCPKG_OSX_DEPLOYMENT_TARGET ${VCPKG_OSX_DEPLOYMENT_TARGET})
        message(STATUS "Major.Minor OSX system Version: ${VCPKG_OSX_DEPLOYMENT_TARGET}")

        set(ENV{QMAKE_MACOSX_DEPLOYMENT_TARGET} ${VCPKG_OSX_DEPLOYMENT_TARGET})
        if(${VCPKG_OSX_DEPLOYMENT_TARGET} GREATER "10.15") # Max Version supported by QT. This version is defined in mkspecs/common/macx.conf as QT_MAC_SDK_VERSION_MAX
            message(STATUS "Qt ${QT_MAJOR_MINOR_VER}.${QT_PATCH_VER} only support OSX_DEPLOYMENT_TARGET up to 10.15")
            set(VCPKG_OSX_DEPLOYMENT_TARGET "10.15")
        endif()
        set(ENV{QMAKE_MACOSX_DEPLOYMENT_TARGET} ${VCPKG_OSX_DEPLOYMENT_TARGET})
        message(STATUS "Enviromnent OSX SDK Version: $ENV{QMAKE_MACOSX_DEPLOYMENT_TARGET}")
        FILE(READ "${SOURCE_PATH}/mkspecs/common/macx.conf" _tmp_contents)
        string(REPLACE "QMAKE_MACOSX_DEPLOYMENT_TARGET = 10.13" "QMAKE_MACOSX_DEPLOYMENT_TARGET = ${VCPKG_OSX_DEPLOYMENT_TARGET}" _tmp_contents ${_tmp_contents})
        FILE(WRITE "${SOURCE_PATH}/mkspecs/common/macx.conf" ${_tmp_contents})
    endif()
    #list(APPEND QT_PLATFORM_CONFIGURE_OPTIONS HOST_PLATFORM ${TARGET_MKSPEC})
    list(APPEND RELEASE_OPTIONS
            "SQLITE_LIBS=${SQLITE_RELEASE} -ldl -lpthread"
            "OPENSSL_LIBS=${SSL_RELEASE} ${EAY_RELEASE} -ldl -lpthread"
            "FONTCONFIG_LIBS=${FONTCONFIG_RELEASE} ${FREETYPE_RELEASE} ${EXPAT_RELEASE} -liconv"
        )
    list(APPEND DEBUG_OPTIONS
            "SQLITE_LIBS=${SQLITE_DEBUG} -ldl -lpthread"
            "OPENSSL_LIBS=${SSL_DEBUG} ${EAY_DEBUG} -ldl -lpthread"
            "FONTCONFIG_LIBS=${FONTCONFIG_DEBUG} ${FREETYPE_DEBUG} ${EXPAT_DEBUG} -liconv"
        )
endif()

## Do not build tests or examples
list(APPEND CORE_OPTIONS
    -nomake examples
    -nomake tests)

if(QT_UPDATE_VERSION)
    SET(VCPKG_POLICY_EMPTY_PACKAGE enabled)
else()
    configure_qt(
        SOURCE_PATH ${SOURCE_PATH}
        ${QT_PLATFORM_CONFIGURE_OPTIONS}
        OPTIONS ${CORE_OPTIONS}
        OPTIONS_RELEASE ${RELEASE_OPTIONS}
        OPTIONS_DEBUG ${DEBUG_OPTIONS}
        )
    install_qt()

    #########################
    #TODO: Make this a function since it is also done by modular scripts!
    # e.g. by patching mkspecs/features/qt_tools.prf somehow
    file(GLOB_RECURSE PRL_FILES "${CURRENT_PACKAGES_DIR}/lib/*.prl" "${CURRENT_PACKAGES_DIR}/tools/qt5/lib/*.prl" "${CURRENT_PACKAGES_DIR}/tools/qt5/mkspecs/*.pri"
                                "${CURRENT_PACKAGES_DIR}/debug/lib/*.prl" "${CURRENT_PACKAGES_DIR}/tools/qt5/debug/lib/*.prl" "${CURRENT_PACKAGES_DIR}/tools/qt5/debug/mkspecs/*.pri")

    file(TO_CMAKE_PATH "${CURRENT_INSTALLED_DIR}/include" CMAKE_INCLUDE_PATH)

    if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "release")
        qt_fix_prl("${CURRENT_INSTALLED_DIR}" "${PRL_FILES}")
        file(COPY ${CMAKE_CURRENT_LIST_DIR}/qtdeploy.ps1 DESTINATION ${CURRENT_PACKAGES_DIR}/plugins)
    endif()

    if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "debug")
        qt_fix_prl("${CURRENT_INSTALLED_DIR}/debug" "${PRL_FILES}")
        file(COPY ${CMAKE_CURRENT_LIST_DIR}/qtdeploy.ps1 DESTINATION ${CURRENT_PACKAGES_DIR}/debug/plugins)
    endif()

    file(MAKE_DIRECTORY ${CURRENT_PACKAGES_DIR}/share)
    file(RENAME ${CURRENT_PACKAGES_DIR}/lib/cmake ${CURRENT_PACKAGES_DIR}/share/cmake)
    file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/lib/cmake) # TODO: check if important debug information for cmake is lost

    #This needs a new VCPKG policy or a static angle build (ANGLE needs to be fixed in VCPKG!)
    if(VCPKG_TARGET_IS_WINDOWS AND ${VCPKG_LIBRARY_LINKAGE} MATCHES "static") # Move angle dll libraries
        if(EXISTS "${CURRENT_PACKAGES_DIR}/bin")
            message(STATUS "Moving ANGLE dlls from /bin to /tools/qt5-angle/bin. In static builds dlls are not allowed in /bin")
            file(MAKE_DIRECTORY ${CURRENT_PACKAGES_DIR}/tools/qt5-angle)
            file(RENAME ${CURRENT_PACKAGES_DIR}/bin ${CURRENT_PACKAGES_DIR}/tools/qt5-angle/bin)
            if(EXISTS ${CURRENT_PACKAGES_DIR}/debug/bin)
                file(MAKE_DIRECTORY ${CURRENT_PACKAGES_DIR}/tools/qt5-angle/debug)
                file(RENAME ${CURRENT_PACKAGES_DIR}/debug/bin ${CURRENT_PACKAGES_DIR}/tools/qt5-angle/debug/bin)
            endif()
        endif()
    endif()

    ## Fix location of qtmain(d).lib. Has been moved into manual-link. Add debug version
    set(cmakefile "${CURRENT_PACKAGES_DIR}/share/cmake/Qt5Core/Qt5CoreConfigExtras.cmake")
    file(READ "${cmakefile}" _contents)
    if(VCPKG_TARGET_IS_WINDOWS AND NOT VCPKG_BUILD_TYPE)
        string(REPLACE "set_property(TARGET Qt5::WinMain APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)" "set_property(TARGET Qt5::WinMain APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE DEBUG)" _contents "${_contents}")
        string(REPLACE
        [[set(imported_location "${_qt5Core_install_prefix}/lib/qtmain.lib")]]
        [[set(imported_location_release "${_qt5Core_install_prefix}/lib/manual-link/qtmain.lib")
          set(imported_location_debug "${_qt5Core_install_prefix}/debug/lib/manual-link/qtmaind.lib")]]
          _contents "${_contents}")
        string(REPLACE
[[    set_target_properties(Qt5::WinMain PROPERTIES
        IMPORTED_LOCATION_RELEASE ${imported_location}
    )]]
[[    set_target_properties(Qt5::WinMain PROPERTIES
        IMPORTED_LOCATION_RELEASE ${imported_location_release}
        IMPORTED_LOCATION_DEBUG ${imported_location_debug}
    )]]
    _contents "${_contents}")
    else() # Single configuration build (either debug or release)
        # Release case
        string(REPLACE
            [[set(imported_location "${_qt5Core_install_prefix}/lib/qtmain.lib")]]
            [[set(imported_location "${_qt5Core_install_prefix}/lib/manual-link/qtmain.lib")]]
            _contents "${_contents}")
        # Debug case (whichever will match)
        string(REPLACE
            [[set(imported_location "${_qt5Core_install_prefix}/lib/qtmaind.lib")]]
            [[set(imported_location "${_qt5Core_install_prefix}/debug/lib/manual-link/qtmaind.lib")]]
            _contents "${_contents}")
        string(REPLACE
            [[set(imported_location "${_qt5Core_install_prefix}/debug/lib/qtmaind.lib")]]
            [[set(imported_location "${_qt5Core_install_prefix}/debug/lib/manual-link/qtmaind.lib")]]
            _contents "${_contents}")
    endif()
    file(WRITE "${cmakefile}" "${_contents}")

    if(EXISTS ${CURRENT_PACKAGES_DIR}/tools/qt5/bin)
        file(COPY ${CURRENT_PACKAGES_DIR}/tools/qt5/bin DESTINATION ${CURRENT_PACKAGES_DIR}/tools/${PORT})
        vcpkg_copy_tool_dependencies(${CURRENT_PACKAGES_DIR}/tools/${PORT}/bin)
        vcpkg_copy_tool_dependencies(${CURRENT_PACKAGES_DIR}/tools/qt5/bin)
    endif()
    # This should be removed if possible! (Currently debug build of qt5-translations requires it.)
    if(EXISTS ${CURRENT_PACKAGES_DIR}/debug/tools/qt5/bin)
        file(COPY ${CURRENT_PACKAGES_DIR}/tools/qt5/bin DESTINATION ${CURRENT_PACKAGES_DIR}/tools/qt5/debug)
        vcpkg_copy_tool_dependencies(${CURRENT_PACKAGES_DIR}/tools/qt5/debug/bin)
    endif()

    if(EXISTS ${CURRENT_PACKAGES_DIR}/tools/qt5/bin/qt.conf)
        file(REMOVE "${CURRENT_PACKAGES_DIR}/tools/qt5/bin/qt.conf")
    endif()
    set(CURRENT_INSTALLED_DIR_BACKUP "${CURRENT_INSTALLED_DIR}")
    set(CURRENT_INSTALLED_DIR "./../../.." ) # Making the qt.conf relative and not absolute
    configure_file(${CURRENT_PACKAGES_DIR}/tools/qt5/qt_release.conf ${CURRENT_PACKAGES_DIR}/tools/qt5/bin/qt.conf) # This makes the tools at least useable for release
    set(CURRENT_INSTALLED_DIR "${CURRENT_INSTALLED_DIR_BACKUP}")

    qt_install_copyright(${SOURCE_PATH})
endif()
#install scripts for other qt ports
file(COPY
    ${CMAKE_CURRENT_LIST_DIR}/cmake/qt_port_hashes.cmake
    ${CMAKE_CURRENT_LIST_DIR}/cmake/qt_port_functions.cmake
    ${CMAKE_CURRENT_LIST_DIR}/cmake/qt_fix_makefile_install.cmake
    ${CMAKE_CURRENT_LIST_DIR}/cmake/qt_fix_cmake.cmake
    ${CMAKE_CURRENT_LIST_DIR}/cmake/qt_fix_prl.cmake
    ${CMAKE_CURRENT_LIST_DIR}/cmake/qt_download_submodule.cmake
    ${CMAKE_CURRENT_LIST_DIR}/cmake/qt_build_submodule.cmake
    ${CMAKE_CURRENT_LIST_DIR}/cmake/qt_install_copyright.cmake
    ${CMAKE_CURRENT_LIST_DIR}/cmake/qt_submodule_installation.cmake
    DESTINATION
        ${CURRENT_PACKAGES_DIR}/share/qt5
)

# Fix Qt5GuiConfigExtras EGL path
if(VCPKG_TARGET_IS_LINUX)
    set(_file "${CURRENT_PACKAGES_DIR}/share/cmake/Qt5Gui/Qt5GuiConfigExtras.cmake")
    file(READ "${_file}" _contents)
    string(REGEX REPLACE "_qt5gui_find_extra_libs\\\(EGL[^\\\n]+" "_qt5gui_find_extra_libs(EGL \"EGL\" \"\" \"\${_qt5Gui_install_prefix}/include\")\n" _contents "${_contents}")
    file(WRITE "${_file}" "${_contents}")
endif()

vcpkg_fixup_pkgconfig()

if(VCPKG_TARGET_IS_OSX)
    file(GLOB _debug_files "${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig/*_debug.pc")
    foreach(_file ${_debug_files})
        string(REGEX REPLACE "_debug\\.pc$" ".pc" _new_filename "${_file}")
        string(REGEX MATCH "(Qt5[a-zA-Z]+)_debug\\.pc$" _not_used "${_file}")
        set(_name ${CMAKE_MATCH_1})
        file(STRINGS "${_file}" _version REGEX "^(Version):.+$")
        file(WRITE "${_new_filename}" "Name: ${_name}\nDescription: Forwarding to the _debug version by vcpkg\n${_version}\nRequires: ${_name}_debug\n")
    endforeach()
endif()
