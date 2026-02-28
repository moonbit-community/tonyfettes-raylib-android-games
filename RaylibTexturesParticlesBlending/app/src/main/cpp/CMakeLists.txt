cmake_minimum_required(VERSION 3.22.1)
project("raylibtexturesparticlesblending" C)

set(MOONBIT_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../moonbit)
set(NATIVE_APP_GLUE_DIR ${ANDROID_NDK}/sources/android/native_app_glue)

# Pull in raylib + raylib_moonbit targets; sets RAYLIB_MOONBIT_MOON_HOME
set(RAYLIB_MOONBIT_DIR ${MOONBIT_DIR}/.mooncakes/tonyfettes/raylib)
add_subdirectory(${RAYLIB_MOONBIT_DIR} raylib_build)

find_program(MOON_EXECUTABLE moon REQUIRED)

set(MOONBIT_GENERATED_C
    ${MOONBIT_DIR}/_build/native/debug/build/raylibtexturesparticlesblending.c)
add_custom_command(
    OUTPUT  ${MOONBIT_GENERATED_C}
    COMMAND ${MOON_EXECUTABLE} build --target native
    WORKING_DIRECTORY ${MOONBIT_DIR}
    DEPENDS ${MOONBIT_DIR}/main.mbt
    COMMENT "Compiling MoonBit to C"
)

# Compile runtime.c in isolation: only MOON_HOME/include, no raylib paths.
# internal/raylib/external/dirent.h would shadow system dirent.h otherwise.
add_library(moonbit_runtime OBJECT
    ${RAYLIB_MOONBIT_MOON_HOME}/lib/runtime.c)
target_include_directories(moonbit_runtime PRIVATE
    ${RAYLIB_MOONBIT_MOON_HOME}/include)
target_compile_options(moonbit_runtime PRIVATE
    -fwrapv -fno-strict-aliasing -Wno-unused-value)

add_library(raylibtexturesparticlesblending SHARED
    ${MOONBIT_GENERATED_C}
    $<TARGET_OBJECTS:moonbit_runtime>
    ${NATIVE_APP_GLUE_DIR}/android_native_app_glue.c
)
target_include_directories(raylibtexturesparticlesblending PRIVATE
    ${NATIVE_APP_GLUE_DIR})
target_compile_definitions(raylibtexturesparticlesblending PRIVATE PLATFORM_ANDROID)
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -u ANativeActivity_onCreate")
# raylib_moonbit brings in: stubs + raylib core + Android system libs +
# MOON_HOME/include + RAYLIB_SRC_DIR — all transitively via PUBLIC properties.
target_link_libraries(raylibtexturesparticlesblending raylib_moonbit)
