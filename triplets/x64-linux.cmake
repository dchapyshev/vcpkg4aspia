set(VCPKG_TARGET_ARCHITECTURE x64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)

set(VCPKG_CMAKE_SYSTEM_NAME Linux)

# Build the X11/xcb libraries from vcpkg as static libs instead of deferring to the system packages.
# Without this the X ports (xcb, libx11, libxkbcommon, xcb-util-*, etc.) install empty packages and the
# build links the system shared libraries; we want them statically linked into the host binaries.
set(X_VCPKG_FORCE_VCPKG_X_LIBRARIES ON)

# Same for the Wayland client library (used by the host screen-capture/input code): build it from vcpkg
# as a static lib (with the wayland[force-build] feature) instead of linking the system libwayland-client.
set(X_VCPKG_FORCE_VCPKG_WAYLAND_LIBRARIES ON)

