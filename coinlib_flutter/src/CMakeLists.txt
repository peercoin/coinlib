# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(coinlib_library VERSION 1.0.0 LANGUAGES C)

# Build secp256k1 using the ExternalProject module

include(ExternalProject)

set(SECP256K1_PREFIX ${CMAKE_BINARY_DIR}/secp256k1)
set(SECP256K1_CFLAGS "-O2 ${CMAKE_C_FLAGS}")

set(
  SECP256K1_ARGS
  -DCMAKE_INSTALL_PREFIX=${SECP256K1_PREFIX}
  -DSECP256K1_ENABLE_MODULE_RECOVERY=ON
  -DSECP256K1_BUILD_TESTS=OFF
  -DSECP256K1_BUILD_EXHAUSTIVE_TESTS=OFF
  -DSECP256K1_BUILD_BENCHMARK=OFF
  -DSECP256K1_BUILD_CTIME_TESTS=OFF
  -DCMAKE_C_FLAGS=${SECP256K1_CFLAGS}

  # Passthrough options
  -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
  -DCMAKE_MAKE_PROGRAM=${CMAKE_MAKE_PROGRAM}
  -DCMAKE_SYSYEM_NAME=${CMAKE_SYSTEM_NAME}
)

# The Android toolchain requires additional settings passed through
if (${CMAKE_SYSTEM_NAME} STREQUAL Android)
  set(
    SECP256K1_ARGS
    ${SECP256K1_ARGS}
    -DANDROID_NDK=${ANDROID_NDK}
    -DANDROID_ABI=${ANDROID_ABI}
    -DANDROID_PLATFORM=${ANDROID_PLATFORM}
  )
endif()

ExternalProject_Add(

  secp256k1

  GIT_REPOSITORY https://github.com/bitcoin-core/secp256k1
  GIT_TAG bdf39000b9c6a0818e7149ccb500873d079e6e85 # v0.3.0 with cmake system

  PREFIX ${SECP256K1_PREFIX}

  # This is necessary to ensure CMake doesn't add cache settings
  CMAKE_GENERATOR ${CMAKE_GENERATOR}

  CMAKE_ARGS ${SECP256K1_ARGS}

)

# Post-build processing of library file
# Move output library to the correct place

set(SECP256K1_VERSIONEDLIB ${SECP256K1_PREFIX}/lib/libsecp256k1.so.2.0.0)
set(SECP255K1_FINALLIB ${SECP256K1_PREFIX}/lib/libsecp256k1.so)

# Move any versioned .so file to an unversioned .so file.
# If the versioned file doesn't exist this shouldn't fail as the destination
# should have been built already
add_custom_target(
  removeVersion
  ALL
  COMMAND ${CMAKE_COMMAND} -E rename
    ${SECP256K1_VERSIONEDLIB}
    ${SECP255K1_FINALLIB}
    || exit 0
)
add_dependencies(removeVersion secp256k1)

# For Android, move library to JNI directory
if (${CMAKE_SYSTEM_NAME} STREQUAL Android)
  set(
    JNI_DIR
    ${CMAKE_CURRENT_SOURCE_DIR}/../android/src/main/jniLibs/${ANDROID_ABI}
  )
  add_custom_target(
    moveAndroid
    ALL
    COMMAND mkdir -p ${JNI_DIR}
    COMMAND ${CMAKE_COMMAND} -E rename
      ${SECP255K1_FINALLIB}
      ${JNI_DIR}/libsecp256k1.so
  )
  add_dependencies(moveAndroid removeVersion)
endif()

