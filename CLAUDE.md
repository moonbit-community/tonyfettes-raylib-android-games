# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Project Overview

Android game/demo apps built with **MoonBit** and **raylib**. Each `Raylib*/` directory is a standalone Android Gradle project. There are ~314 projects total:

- **Game projects** (`*2026`, plus classic game remakes like `RaylibContra1987Lite`) — ~156 projects
- **Example/demo projects** (raylib API examples: `RaylibCore*`, `RaylibShapes*`, `RaylibTextures*`, etc.) — ~158 projects

All projects use the **`raylib/`** git submodule (`tonyfettes/raylib`) as a local path dependency — both in `moon.mod.json` and `CMakeLists.txt`.

## Prerequisites

- **Android SDK** (set `ANDROID_HOME` if not at the default location)
- **Android NDK** 28.x (installed via SDK Manager)
- **CMake** 3.22.1 (installed via SDK Manager)
- **Java 21+** — system JDK or Android Studio's bundled JBR both work. Ensure `java` is on `PATH` or set `JAVA_HOME`.
- **MoonBit** (`moon` CLI) — ensure `moon` is on `PATH`

## Build Commands

```bash
# Build a single project
cd RaylibCoreBasicWindow
./gradlew assembleDebug --no-daemon

# Build all game projects in parallel (uses scripts/build_games.sh)
bash scripts/build_games.sh

# Build specific projects
bash scripts/build_games.sh RaylibCoreBasicWindow RaylibShapesBouncingBall

# Install & launch on emulator/device
adb install -r RaylibCoreBasicWindow/app/build/outputs/apk/debug/app-debug.apk
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

## Gotchas

- **`build_games.sh` only builds game projects by default** — It filters to `*2026` + classic games. To build example/demo projects, pass them explicitly: `bash scripts/build_games.sh RaylibCoreBasicWindow`.
- **`local.properties` must exist** in each project with `sdk.dir=...`. The build script creates it automatically, but for manual single-project builds you may need to create it first.
- **APK output path** is `app/build/outputs/apk/debug/app-debug.apk`.
- **All apps use `android.app.NativeActivity`** — there is no custom Java Activity class.
- **If `java` is not on PATH**, set `JAVA_HOME` to your JDK or to Android Studio's bundled JBR (e.g. on macOS: `/Applications/Android Studio.app/Contents/jbr/Contents/Home`).
- **If `moon` is not on PATH**, add it (e.g. `export PATH="$HOME/.moon/bin:$PATH"`).

## Conventions

- Use conventional commits (`feat:`, `fix:`, `refactor:`)
- Each project's `applicationId` follows the pattern `com.example.raylib<lowercasename>`
- The shared library name matches the lowercase project name (e.g., `libraylibcorebasicwindow.so`)
- Android `minSdk = 26`, `targetSdk = 36`, `compileSdk = 36`
