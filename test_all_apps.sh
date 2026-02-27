#!/usr/bin/env bash
# test_all_apps.sh — Build all 318 Android projects, install on emulator-5554,
# take screenshots at 1/3/5 s, check for crashes, uninstall.

set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEVICE="emulator-5554"
MAX_PARALLEL=8
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_LOG="${BASE_DIR}/test_results_${TIMESTAMP}.log"
BUILD_LOGS_DIR="${BASE_DIR}/build_logs"
LOGCAT_DIR="${BASE_DIR}/logcat"

mkdir -p "${BUILD_LOGS_DIR}" "${LOGCAT_DIR}"

# Ensure ANDROID_HOME is set (needed by Gradle when local.properties is absent)
export ANDROID_HOME="${ANDROID_HOME:-/Users/haoxiang/Library/Android/sdk}"

# ─── Helpers ────────────────────────────────────────────────────────────────

log() { echo "$*" | tee -a "${RESULTS_LOG}"; }

extract_pkg() {
    local proj_dir="$1"
    grep 'applicationId = ' "${proj_dir}/app/build.gradle.kts" 2>/dev/null \
        | sed 's/.*"\(.*\)".*/\1/' | tr -d '[:space:]' | head -1
}

# ─── Phase 1: Discover Projects ─────────────────────────────────────────────

log "=== Phase 1: Discovering projects ==="
CLASSIC_GAMES="RaylibBattleCity RaylibMinesweeper RaylibContra1987Lite \
               RaylibSuperMario1985Lite RaylibFighter97Lite RaylibJackal1988Lite \
               RaylibBomberman1983Lite"
PROJECTS=()
while IFS= read -r d; do
    name=$(basename "$d")
    [[ ! -f "${d}/gradlew" ]] && continue
    if [[ "$name" == *2026 ]] || [[ " $CLASSIC_GAMES " == *" $name "* ]]; then
        PROJECTS+=("$d")
    fi
done < <(find "${BASE_DIR}" -maxdepth 1 -mindepth 1 -type d | sort)

TOTAL=${#PROJECTS[@]}
log "Found ${TOTAL} projects with gradlew."

# ─── Phase 1b: Ensure local.properties for every project ────────────────────

log "=== Phase 1b: Writing missing local.properties ==="
SDK_DIR="${ANDROID_HOME}"
WROTE_LP=0
for proj_dir in "${PROJECTS[@]}"; do
    lp="${proj_dir}/local.properties"
    if [[ ! -f "${lp}" ]]; then
        echo "sdk.dir=${SDK_DIR}" > "${lp}"
        WROTE_LP=$((WROTE_LP + 1))
    fi
done
log "Wrote local.properties to ${WROTE_LP} projects (${SDK_DIR})."

# ─── Phase 1: Parallel Builds ───────────────────────────────────────────────

log ""
log "=== Phase 1: Parallel builds (MAX_PARALLEL=${MAX_PARALLEL}) ==="

declare -A BUILD_STATUS   # [proj_name]=PASS|FAIL

build_project() {
    local proj_dir="$1"
    local proj_name
    proj_name=$(basename "${proj_dir}")
    local log_file="${BUILD_LOGS_DIR}/${proj_name}.log"

    cd "${proj_dir}"
    if ./gradlew assembleDebug --no-daemon -q \
            >"${log_file}" 2>&1; then
        echo "BUILD_PASS:${proj_dir}"
    else
        echo "BUILD_FAIL:${proj_dir}"
    fi
}

export -f build_project
export BUILD_LOGS_DIR

BATCH_PIDS=()
BATCH_RESULTS_DIR="${BASE_DIR}/.build_results_${TIMESTAMP}"
mkdir -p "${BATCH_RESULTS_DIR}"

for proj_dir in "${PROJECTS[@]}"; do
    proj_name=$(basename "${proj_dir}")
    result_file="${BATCH_RESULTS_DIR}/${proj_name}.result"

    (
        cd "${proj_dir}"
        log_file="${BUILD_LOGS_DIR}/${proj_name}.log"
        if ./gradlew assembleDebug --no-daemon -q \
                >"${log_file}" 2>&1; then
            echo "PASS" > "${result_file}"
        else
            echo "FAIL" > "${result_file}"
        fi
    ) &
    BATCH_PIDS+=($!)

    # When we've launched MAX_PARALLEL jobs, wait for all of them
    if (( ${#BATCH_PIDS[@]} >= MAX_PARALLEL )); then
        for pid in "${BATCH_PIDS[@]}"; do
            wait "${pid}" || true
        done
        BATCH_PIDS=()
    fi
done

# Wait for any remaining background jobs
for pid in "${BATCH_PIDS[@]}"; do
    wait "${pid}" || true
done

# Collect build results
BUILD_PASS_LIST=()
BUILD_FAIL_COUNT=0
for proj_dir in "${PROJECTS[@]}"; do
    proj_name=$(basename "${proj_dir}")
    result_file="${BATCH_RESULTS_DIR}/${proj_name}.result"
    if [[ -f "${result_file}" ]] && [[ "$(cat "${result_file}")" == "PASS" ]]; then
        BUILD_PASS_LIST+=("${proj_dir}")
        log "BUILD PASS: ${proj_name}"
    else
        (( BUILD_FAIL_COUNT++ )) || true
        log "BUILD FAIL: ${proj_name}"
    fi
done

rm -rf "${BATCH_RESULTS_DIR}"

log ""
log "Build summary: ${#BUILD_PASS_LIST[@]} passed, ${BUILD_FAIL_COUNT} failed out of ${TOTAL}."

# ─── Phase 2: Sequential Install / Launch / Screenshot / Check ──────────────

log ""
log "=== Phase 2: Install / Launch / Screenshot (device: ${DEVICE}) ==="

PASS_COUNT=0
FAIL_COUNT=0

for proj_dir in "${BUILD_PASS_LIST[@]}"; do
    proj_name=$(basename "${proj_dir}")
    apk_path="${proj_dir}/app/build/outputs/apk/debug/app-debug.apk"
    screenshots_dir="${proj_dir}/screenshots"

    if [[ ! -f "${apk_path}" ]]; then
        log "FAIL:NO_APK  ${proj_name}"
        (( FAIL_COUNT++ )) || true
        continue
    fi

    pkg=$(extract_pkg "${proj_dir}")
    if [[ -z "${pkg}" ]]; then
        log "FAIL:NO_PKG  ${proj_name}"
        (( FAIL_COUNT++ )) || true
        continue
    fi

    log ""
    log "--- ${proj_name} (${pkg}) ---"

    # 1. Install
    if ! adb -s "${DEVICE}" install -r "${apk_path}" >/dev/null 2>&1; then
        log "FAIL:INSTALL  ${proj_name}"
        (( FAIL_COUNT++ )) || true
        continue
    fi

    # 2. Clear logcat
    adb -s "${DEVICE}" logcat -c 2>/dev/null || true

    # 3. Launch
    adb -s "${DEVICE}" shell am start -n "${pkg}/.MainActivity" >/dev/null 2>&1 || true

    # 4–6. Screenshots at 1 / 3 / 5 seconds
    mkdir -p "${screenshots_dir}"

    sleep 1
    adb -s "${DEVICE}" exec-out screencap -p \
        > "${screenshots_dir}/screenshot_1s.png" 2>/dev/null || true

    sleep 2
    adb -s "${DEVICE}" exec-out screencap -p \
        > "${screenshots_dir}/screenshot_3s.png" 2>/dev/null || true

    sleep 2
    adb -s "${DEVICE}" exec-out screencap -p \
        > "${screenshots_dir}/screenshot_5s.png" 2>/dev/null || true

    # 7. Save logcat
    adb -s "${DEVICE}" logcat -d \
        > "${LOGCAT_DIR}/${proj_name}.log" 2>/dev/null || true

    # 8. Crash check
    CRASHED=0
    CRASH_EXCERPT=""
    if grep -q "FATAL EXCEPTION" "${LOGCAT_DIR}/${proj_name}.log" 2>/dev/null; then
        CRASHED=1
        CRASH_EXCERPT=$(grep -A 3 "FATAL EXCEPTION" \
            "${LOGCAT_DIR}/${proj_name}.log" 2>/dev/null | head -4 || true)
    fi
    PID_CHECK=$(adb -s "${DEVICE}" shell pidof "${pkg}" 2>/dev/null | tr -d '[:space:]' || true)
    if [[ -z "${PID_CHECK}" ]]; then
        CRASHED=1
        if [[ -z "${CRASH_EXCERPT}" ]]; then
            CRASH_EXCERPT="Process not running after 5 s"
        fi
    fi

    # 9. Log result
    if (( CRASHED )); then
        log "FAIL:CRASH  ${proj_name}  |  ${CRASH_EXCERPT}"
        (( FAIL_COUNT++ )) || true
    else
        log "PASS  ${proj_name}"
        (( PASS_COUNT++ )) || true
    fi

    # 10. Cleanup
    adb -s "${DEVICE}" shell am force-stop "${pkg}" >/dev/null 2>&1 || true
    adb -s "${DEVICE}" uninstall "${pkg}" >/dev/null 2>&1 || true
done

# ─── Final Summary ───────────────────────────────────────────────────────────

log ""
log "========================================================"
log "FINAL SUMMARY"
log "  Total projects :  ${TOTAL}"
log "  Build passed   :  ${#BUILD_PASS_LIST[@]}"
log "  Build failed   :  ${BUILD_FAIL_COUNT}"
log "  Runtime PASS   :  ${PASS_COUNT}"
log "  Runtime FAIL   :  ${FAIL_COUNT}"
log "========================================================"
log "Results log : ${RESULTS_LOG}"
log "Build logs  : ${BUILD_LOGS_DIR}/"
log "Logcat dumps: ${LOGCAT_DIR}/"
log "Screenshots : <each project>/screenshots/"
