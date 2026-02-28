cmake_minimum_required(VERSION 3.22.1)
project("raylibnetworkcurl" C)

# --- Paths ---
set(MOONBIT_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../moonbit)
set(NATIVE_APP_GLUE_DIR ${ANDROID_NDK}/sources/android/native_app_glue)

# MOON_HOME: use env var, fallback to $HOME/.moon
if(DEFINED ENV{MOON_HOME})
    set(MOON_HOME "$ENV{MOON_HOME}")
else()
    set(MOON_HOME "$ENV{HOME}/.moon")
endif()

# Raylib + MoonBit bindings from local submodule
set(RAYLIB_BINDINGS_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../../../../../raylib/internal/raylib)
set(RAYLIB_SRC_DIR ${RAYLIB_BINDINGS_DIR})

# Async C stubs from local submodule
set(ASYNC_SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../../../../../async/src)

# --- Find moon CLI ---
find_program(MOON_EXECUTABLE moon REQUIRED)

# --- Step 1: Run moon build to generate C ---
set(MOONBIT_GENERATED_C ${MOONBIT_DIR}/_build/native/debug/build/raylibnetworkcurl.c)
add_custom_command(
    OUTPUT ${MOONBIT_GENERATED_C}
    COMMAND ${MOON_EXECUTABLE} build --target native
    WORKING_DIRECTORY ${MOONBIT_DIR}
    DEPENDS ${MOONBIT_DIR}/main.mbt
    COMMENT "Compiling MoonBit to C"
)

# --- Step 2: Build raylib static library (from local submodule) ---
add_library(raylib STATIC
    ${RAYLIB_SRC_DIR}/rcore.c
    ${RAYLIB_SRC_DIR}/rshapes.c
    ${RAYLIB_SRC_DIR}/rtextures.c
    ${RAYLIB_SRC_DIR}/rtext.c
    ${RAYLIB_SRC_DIR}/rmodels.c
    ${RAYLIB_SRC_DIR}/raudio.c
    ${RAYLIB_SRC_DIR}/utils.c
)
target_include_directories(raylib PUBLIC ${RAYLIB_SRC_DIR} ${RAYLIB_SRC_DIR}/external/glfw/include)
target_include_directories(raylib PRIVATE ${NATIVE_APP_GLUE_DIR})
target_compile_definitions(raylib PUBLIC PLATFORM_ANDROID GRAPHICS_API_OPENGL_ES2 _DEFAULT_SOURCE)
target_compile_options(raylib PRIVATE -std=c99 -ffunction-sections -fdata-sections -fPIC)

# --- Step 3: Build game shared library ---
add_library(raylibnetworkcurl SHARED
    ${MOONBIT_GENERATED_C}
    ${MOON_HOME}/lib/runtime.c
    # Raylib MoonBit binding stubs
    ${RAYLIB_BINDINGS_DIR}/stub_audio.c
    ${RAYLIB_BINDINGS_DIR}/stub_automation.c
    ${RAYLIB_BINDINGS_DIR}/stub_camera.c
    ${RAYLIB_BINDINGS_DIR}/stub_color.c
    ${RAYLIB_BINDINGS_DIR}/stub_drawing.c
    ${RAYLIB_BINDINGS_DIR}/stub_filesystem.c
    ${RAYLIB_BINDINGS_DIR}/stub_image_drawing.c
    ${RAYLIB_BINDINGS_DIR}/stub_image_processing.c
    ${RAYLIB_BINDINGS_DIR}/stub_input.c
    ${RAYLIB_BINDINGS_DIR}/stub_models.c
    ${RAYLIB_BINDINGS_DIR}/stub_shapes.c
    ${RAYLIB_BINDINGS_DIR}/stub_text.c
    ${RAYLIB_BINDINGS_DIR}/stub_textures.c
    ${RAYLIB_BINDINGS_DIR}/stub_utils.c
    ${RAYLIB_BINDINGS_DIR}/stub_window.c
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

target_include_directories(raylibnetworkcurl PRIVATE
    ${NATIVE_APP_GLUE_DIR}
    ${MOON_HOME}/include
    ${RAYLIB_SRC_DIR}
)

target_compile_definitions(raylibnetworkcurl PUBLIC PLATFORM_ANDROID)
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -u ANativeActivity_onCreate")

target_link_libraries(raylibnetworkcurl raylib android log EGL GLESv2 OpenSLES atomic m dl)
