# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Project Overview

Android game/demo apps built with **MoonBit** and **raylib**. Each `Raylib*/` directory is a standalone Android Gradle project. There are ~314 projects total:

- **Game projects** (`*2026`, plus classic game remakes like `RaylibContra1987Lite`) — ~156 projects
- **Example/demo projects** (raylib API examples: `RaylibCore*`, `RaylibShapes*`, `RaylibTextures*`, etc.) — ~158 projects

All projects use the **`raylib/`** git submodule (`tonyfettes/raylib`) as a local path dependency — both in `moon.mod.json` and `CMakeLists.txt`.

## Prerequisites

- **Android SDK** at `~/Library/Android/sdk` (or set `ANDROID_HOME`)
- **Android NDK** 28.x (installed via SDK Manager)
- **CMake** 3.22.1 (installed via SDK Manager)
- **Java 21** — use Android Studio's bundled JBR: `JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"`
- **MoonBit** (`moon` CLI) at `~/.moon/bin/moon`

## Build Commands

```bash
# Build a single project
cd RaylibCoreBasicWindow
JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" \
ANDROID_HOME="$HOME/Library/Android/sdk" \
PATH="$HOME/.moon/bin:$JAVA_HOME/bin:$PATH" \
./gradlew assembleDebug --no-daemon

# Build all game projects in parallel (uses scripts/build_games.sh)
JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" \
PATH="$HOME/.moon/bin:$JAVA_HOME/bin:$PATH" \
bash scripts/build_games.sh

# Build specific projects
JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" \
PATH="$HOME/.moon/bin:$JAVA_HOME/bin:$PATH" \
bash scripts/build_games.sh RaylibCoreBasicWindow RaylibShapesBouncingBall

# Install & launch on emulator
adb install -r RaylibCoreBasicWindow/app/build/intermediates/apk/debug/app-debug.apk
adb shell am start -n com.example.raylibcorebasicwindow/android.app.NativeActivity
```

## Project Structure

```
Raylib<Name>/
  app/
    build.gradle.kts          # Android build config (namespace, applicationId, NDK ABI filters)
    src/main/
      cpp/
        CMakeLists.txt         # Native build: moon build -> C, then compile raylib + game .so
      moonbit/
        main.mbt               # MoonBit game source
        moon.mod.json           # MoonBit module config (deps on tonyfettes/raylib via local path)
        moon.pkg                # MoonBit package config
      assets/                   # Game assets (textures, sounds, shaders) — optional
      res/                      # Android resources
  gradlew                       # Gradle wrapper
  local.properties              # sdk.dir (auto-generated)
```

## Build Pipeline

1. **MoonBit compile** — `moon build --target native` generates a `.c` file from `main.mbt`
2. **raylib static lib** — Compiled from vendored C sources in `raylib/internal/raylib/` (the git submodule)
3. **Game shared lib** — Links generated C + MoonBit runtime + raylib stub bindings + raylib → `.so`
4. **Gradle package** — Bundles `.so` into APK for `arm64-v8a`, `armeabi-v7a`, `x86_64`

## Key Dependencies

- **`raylib/`** (git submodule) — `tonyfettes/raylib` MoonBit bindings + vendored raylib 5.5 C sources
  - All projects reference this via `"tonyfettes/raylib": { "path": "../../../../../raylib" }` in `moon.mod.json`
  - CMakeLists.txt uses `${CMAKE_CURRENT_SOURCE_DIR}/../../../../../raylib/internal/raylib` for C sources
- **`scripts/build_games.sh`** — Parallel build script (default 8 jobs, configurable via `MAX_PARALLEL`)
- **`scripts/upload_apks.sh`** — Upload built APKs

## Conventions

- Use conventional commits (`feat:`, `fix:`, `refactor:`)
- Each project's `applicationId` follows the pattern `com.example.raylib<lowercasename>`
- The shared library name matches the lowercase project name (e.g., `libraylibcorebasicwindow.so`)
- Android `minSdk = 26`, `targetSdk = 36`, `compileSdk = 36`
