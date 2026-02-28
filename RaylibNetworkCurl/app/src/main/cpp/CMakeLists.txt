cmake_minimum_required(VERSION 3.22.1)
project("raylibnetworkcurl" C)

# --- Paths ---
set(MOONBIT_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../moonbit)
set(NATIVE_APP_GLUE_DIR ${ANDROID_NDK}/sources/android/native_app_glue)

# Async C stubs from local submodule
set(ASYNC_SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../../../../../async/src)

# --- Run moon check at configure time to refresh .mooncakes dependencies ---
find_program(MOON_EXECUTABLE moon REQUIRED)
execute_process(
    COMMAND ${MOON_EXECUTABLE} check --target native
    WORKING_DIRECTORY ${MOONBIT_DIR}
    RESULT_VARIABLE _MOON_CHECK_RC
)
if(_MOON_CHECK_RC)
    message(FATAL_ERROR "moon check failed (rc=${_MOON_CHECK_RC})")
endif()

# --- Step 1: Load raylib + raylib_moonbit from mooncakes ---
add_subdirectory(
    ${MOONBIT_DIR}/.mooncakes/tonyfettes/raylib
    ${CMAKE_CURRENT_BINARY_DIR}/raylib_moonbit
)

# --- Step 2: Run moon build to generate C ---
set(MOONBIT_GENERATED_C ${MOONBIT_DIR}/_build/native/debug/build/raylibnetworkcurl.c)
add_custom_target(moonbit_codegen ALL
    COMMAND ${MOON_EXECUTABLE} build --target native
    WORKING_DIRECTORY ${MOONBIT_DIR}
    COMMENT "Compiling MoonBit to C"
)

# --- Step 3: Build game shared library ---
add_library(raylibnetworkcurl SHARED
    ${MOONBIT_GENERATED_C}
    ${RAYLIB_MOONBIT_MOON_HOME}/lib/runtime.c
    # Async C stubs (platform-guarded with #ifdef)
    ${ASYNC_SRC_DIR}/internal/c_buffer/stub.c
    ${ASYNC_SRC_DIR}/internal/env_util/stub.c
    ${ASYNC_SRC_DIR}/internal/fd_util/stub.c
    ${ASYNC_SRC_DIR}/internal/os_string/stub.c
    ${ASYNC_SRC_DIR}/internal/time/time.c
    ${ASYNC_SRC_DIR}/internal/event_loop/epoll.c
    ${ASYNC_SRC_DIR}/internal/event_loop/kqueue.c
    ${ASYNC_SRC_DIR}/internal/event_loop/iocp.c
    ${ASYNC_SRC_DIR}/internal/event_loop/io_unix.c
    ${ASYNC_SRC_DIR}/internal/event_loop/io_windows.c
    ${ASYNC_SRC_DIR}/internal/event_loop/thread_pool.c
    ${ASYNC_SRC_DIR}/fs/stub.c
    ${ASYNC_SRC_DIR}/process/stub.c
    ${ASYNC_SRC_DIR}/socket/socket.c
    ${ASYNC_SRC_DIR}/tls/openssl.c
    ${ASYNC_SRC_DIR}/os_error/stub.c
    # Android native app glue
    ${NATIVE_APP_GLUE_DIR}/android_native_app_glue.c
)
add_dependencies(raylibnetworkcurl moonbit_codegen)

target_include_directories(raylibnetworkcurl PRIVATE
    ${NATIVE_APP_GLUE_DIR}
)

target_compile_definitions(raylibnetworkcurl PUBLIC PLATFORM_ANDROID)
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -u ANativeActivity_onCreate")

target_link_libraries(raylibnetworkcurl raylib_moonbit dl)
