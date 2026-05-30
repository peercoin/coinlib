# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
set(PROJECT_NAME "coinlib_flutter")
project(${PROJECT_NAME} LANGUAGES CXX)

# Build secp256k1 via cmake ExternalProject (sets SECP256K1_OUTPUT in this scope).
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/../src" "${CMAKE_CURRENT_BINARY_DIR}/shared")

# Bundle the built secp256k1.dll with the plugin.
set(coinlib_flutter_bundled_libraries
  ${SECP256K1_OUTPUT}
  PARENT_SCOPE
)
