#!/bin/bash
# Cross-compile OpenSSL shared libraries for Android (arm64-v8a, armeabi-v7a, x86_64)
# Requires: ANDROID_HOME or ANDROID_NDK_ROOT, Perl, Make
#
# Usage: bash scripts/build_openssl_android.sh
# Output: openssl/prebuilt/<abi>/libssl.so, libcrypto.so
#
# Follows OpenSSL's official NOTES-ANDROID.md

set -euo pipefail

OPENSSL_VERSION="3.4.1"
OPENSSL_DIR_NAME="openssl-${OPENSSL_VERSION}"
OPENSSL_TARBALL="${OPENSSL_DIR_NAME}.tar.gz"
OPENSSL_URL="https://github.com/openssl/openssl/releases/download/openssl-${OPENSSL_VERSION}/${OPENSSL_TARBALL}"
API_LEVEL=26  # matches Android minSdk

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="${PROJECT_ROOT}/openssl/prebuilt"
BUILD_DIR="${PROJECT_ROOT}/openssl/build"
SRC_DIR="${BUILD_DIR}/${OPENSSL_DIR_NAME}"

# --- Detect NDK ---
if [ -n "${ANDROID_NDK_ROOT:-}" ]; then
    NDK_ROOT="$ANDROID_NDK_ROOT"
elif [ -n "${ANDROID_HOME:-}" ]; then
    NDK_ROOT=$(ls -d "$ANDROID_HOME/ndk/"* 2>/dev/null | sort -V | tail -1)
elif [ -d "$HOME/Library/Android/sdk/ndk" ]; then
    NDK_ROOT=$(ls -d "$HOME/Library/Android/sdk/ndk/"* 2>/dev/null | sort -V | tail -1)
else
    echo "ERROR: Cannot find Android NDK. Set ANDROID_NDK_ROOT or ANDROID_HOME." >&2
    exit 1
fi

if [ ! -d "$NDK_ROOT" ]; then
    echo "ERROR: NDK not found at $NDK_ROOT" >&2
    exit 1
fi

echo "Using NDK: $NDK_ROOT"

# Detect host OS for NDK toolchain
case "$(uname -s)" in
    Linux*)  HOST_TAG="linux-x86_64" ;;
    Darwin*) HOST_TAG="darwin-x86_64" ;;
    *)       echo "ERROR: Unsupported host OS"; exit 1 ;;
esac

TOOLCHAIN="${NDK_ROOT}/toolchains/llvm/prebuilt/${HOST_TAG}"
if [ ! -d "$TOOLCHAIN" ]; then
    echo "ERROR: NDK toolchain not found at $TOOLCHAIN" >&2
    exit 1
fi

# --- ABI configuration ---
# Format: "android_abi:openssl_target"
ABIS=(
    "arm64-v8a:android-arm64"
    "armeabi-v7a:android-arm"
    "x86_64:android-x86_64"
)

# --- Download OpenSSL source if needed ---
mkdir -p "$BUILD_DIR"

if [ ! -d "$SRC_DIR" ]; then
    if [ ! -f "${BUILD_DIR}/${OPENSSL_TARBALL}" ]; then
        echo "Downloading OpenSSL ${OPENSSL_VERSION}..."
        curl -L -o "${BUILD_DIR}/${OPENSSL_TARBALL}" "$OPENSSL_URL"
    fi
    echo "Extracting OpenSSL..."
    tar xzf "${BUILD_DIR}/${OPENSSL_TARBALL}" -C "$BUILD_DIR"
fi

# --- Build for each ABI ---
mkdir -p "$OUTPUT_DIR"

for abi_config in "${ABIS[@]}"; do
    ANDROID_ABI="${abi_config%%:*}"
    OPENSSL_TARGET="${abi_config##*:}"
    ABI_OUTPUT="${OUTPUT_DIR}/${ANDROID_ABI}"

    # Skip if already built
    if [ -f "${ABI_OUTPUT}/libssl.so" ] && [ -f "${ABI_OUTPUT}/libcrypto.so" ]; then
        echo "=== ${ANDROID_ABI}: already built, skipping ==="
        continue
    fi

    echo "=== Building OpenSSL for ${ANDROID_ABI} (${OPENSSL_TARGET}) ==="

    # Build in a separate directory to avoid conflicts
    ABI_BUILD_DIR="${BUILD_DIR}/build-${ANDROID_ABI}"
    rm -rf "$ABI_BUILD_DIR"
    cp -r "$SRC_DIR" "$ABI_BUILD_DIR"

    pushd "$ABI_BUILD_DIR" > /dev/null

    # Set up NDK environment per OpenSSL NOTES-ANDROID.md
    export ANDROID_NDK_ROOT="$NDK_ROOT"
    export PATH="${TOOLCHAIN}/bin:$PATH"

    ./Configure "$OPENSSL_TARGET" \
        -D__ANDROID_API__=${API_LEVEL} \
        shared \
        no-tests \
        no-ui-console \
        no-comp \
        2>&1 | tail -3

    make -j"$(sysctl -n hw.ncpu 2>/dev/null || nproc)" \
        SHLIB_VERSION_NUMBER= \
        SHLIB_EXT=.so \
        2>&1 | tail -5

    popd > /dev/null

    # Copy outputs
    mkdir -p "$ABI_OUTPUT"

    # OpenSSL 3.x produces libssl.so.3 and libcrypto.so.3 (or versioned names)
    # We need them named libssl.so and libcrypto.so for Android dlopen
    for lib in ssl crypto; do
        # Find the actual shared library (not the symlink)
        SO_FILE=$(find "$ABI_BUILD_DIR" -maxdepth 1 -name "lib${lib}.so*" -type f ! -name "*.a" | head -1)
        if [ -z "$SO_FILE" ]; then
            SO_FILE=$(find "$ABI_BUILD_DIR" -maxdepth 1 -name "lib${lib}.so" | head -1)
        fi
        if [ -n "$SO_FILE" ]; then
            cp "$SO_FILE" "${ABI_OUTPUT}/lib${lib}.so"
            echo "  Copied lib${lib}.so ($(du -h "${ABI_OUTPUT}/lib${lib}.so" | cut -f1))"
        else
            echo "ERROR: lib${lib}.so not found in build output!" >&2
            ls -la "$ABI_BUILD_DIR"/lib${lib}.* 2>/dev/null || true
            exit 1
        fi
    done

    echo "=== ${ANDROID_ABI}: done ==="

    # Clean up build dir to save space
    rm -rf "$ABI_BUILD_DIR"
done

echo ""
echo "OpenSSL ${OPENSSL_VERSION} built for all ABIs."
echo "Output: ${OUTPUT_DIR}/"
ls -lR "$OUTPUT_DIR/"
