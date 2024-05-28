# The Flutter SDK has a minimum version of 3.10, but 3.13 is required for
# secp256k1 and most users of this library should have 3.13. Ubuntu 18.04 only
# has CMake 3.10 but this version is old.
cmake_minimum_required(VERSION 3.13)

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
  -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
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
  GIT_TAG e3a885d42a7800c1ccebad94ad1e2b82c4df5c65 # v0.5.0

  PREFIX ${SECP256K1_PREFIX}

  # This is necessary to ensure CMake doesn't add cache settings
  CMAKE_GENERATOR ${CMAKE_GENERATOR}

  CMAKE_ARGS ${SECP256K1_ARGS}

)

# Post-build processing of library file
# Move output library to the correct place

set(SECP256K1_VERSIONEDLIB ${SECP256K1_PREFIX}/lib/libsecp256k1.so.2.2.0)
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
