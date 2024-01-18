# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
set(PROJECT_NAME "coinlib_flutter")
project(${PROJECT_NAME} LANGUAGES CXX)

# Invoke the build for native code shared with the other target platforms.
# This can be changed to accommodate different builds.
# add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/../src" "${CMAKE_CURRENT_BINARY_DIR}/shared")
# TODO re-enable the above line if/when the CMake process is made Windows-compatible.
# See also below.

# Search for secp256k1.dll in multiple possible directories.
#
# This is only necessary because in testing we have found that most Windows hosts
# have CMAKE_BINARY_DIR = app/build/windows/x64, but some use app/build/windows.
# This should search through its multiple possible locations. 
find_file(SECP256K1_DLL
    NAMES secp256k1.dll
    PATHS
        "${CMAKE_BINARY_DIR}/../"           # Check one level up.
        "${CMAKE_BINARY_DIR}/../../"        # Check two levels up.
        "${CMAKE_BINARY_DIR}/../../../"     # Used for the example app.
        "${CMAKE_SOURCE_DIR}/../build"
        "${CMAKE_SOURCE_DIR}/../../build"   # Works for the example app.
    NO_DEFAULT_PATH
)

# Check if SECP256K1_DLL was found
if (SECP256K1_DLL)
    # List of absolute paths to libraries that should be bundled with the plugin.
    # This list could contain prebuilt libraries, or libraries created by an
    # external build triggered from this build file.
    set(coinlib_flutter_bundled_libraries
        # Defined in ../src/CMakeLists.txt.
        # This can be changed to accommodate different builds.
        # $<TARGET_FILE:coinlib_flutter>
        # TODO re-enable if/when the CMake process is made Windows-compatible.
        # See also above.
        ${SECP256K1_DLL}
        PARENT_SCOPE
    )
else ()
    message(FATAL_ERROR "Could not find secp256k1.dll.")
endif ()
