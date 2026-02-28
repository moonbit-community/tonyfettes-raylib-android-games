cmake_minimum_required(VERSION 3.22.1)
project("raylibbombergrid2026" C)

set(MOONBIT_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../moonbit)
set(NATIVE_APP_GLUE_DIR ${ANDROID_NDK}/sources/android/native_app_glue)

# Refresh .mooncakes at configure time so add_subdirectory finds CMakeLists.txt & stubs.
find_program(MOON_EXECUTABLE moon REQUIRED)
execute_process(
    COMMAND ${MOON_EXECUTABLE} check --target native
    WORKING_DIRECTORY ${MOONBIT_DIR}
    RESULT_VARIABLE MOON_RESULT
)
if(NOT MOON_RESULT EQUAL 0)
    message(FATAL_ERROR "moon check failed (exit ${MOON_RESULT})")
endif()

# Pull in raylib + raylib_moonbit targets; sets RAYLIB_MOONBIT_MOON_HOME
set(RAYLIB_MOONBIT_DIR ${MOONBIT_DIR}/.mooncakes/tonyfettes/raylib)
add_subdirectory(${RAYLIB_MOONBIT_DIR} raylib_build)

set(MOONBIT_GENERATED_C
    ${MOONBIT_DIR}/_build/native/debug/build/raylibbombergrid2026.c)
add_custom_target(moonbit_codegen ALL
    COMMAND ${MOON_EXECUTABLE} build --target native
    WORKING_DIRECTORY ${MOONBIT_DIR}
    BYPRODUCTS ${MOONBIT_GENERATED_C}
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

add_library(raylibbombergrid2026 SHARED
    ${MOONBIT_GENERATED_C}
    $<TARGET_OBJECTS:moonbit_runtime>
    ${NATIVE_APP_GLUE_DIR}/android_native_app_glue.c
)
target_include_directories(raylibbombergrid2026 PRIVATE
    ${NATIVE_APP_GLUE_DIR})
target_compile_definitions(raylibbombergrid2026 PRIVATE PLATFORM_ANDROID)
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -u ANativeActivity_onCreate")
# raylib_moonbit brings in: stubs + raylib core + Android system libs +
# MOON_HOME/include + RAYLIB_SRC_DIR — all transitively via PUBLIC properties.
add_dependencies(raylibbombergrid2026 moonbit_codegen)
target_link_libraries(raylibbombergrid2026 raylib_moonbit)
