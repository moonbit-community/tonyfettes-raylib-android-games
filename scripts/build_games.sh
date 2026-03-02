#!/usr/bin/env bash
# build_games.sh — Build all game projects (or a subset) in parallel.
#
# Usage:
#   bash scripts/build_games.sh                    # build all game projects
#   bash scripts/build_games.sh Raylib{A,B}*       # build specific projects
#
# Environment:
#   ANDROID_HOME   — path to Android SDK (default: ~/Library/Android/sdk)
#   MAX_PARALLEL   — parallel build jobs (default: 8)
#   BUILD_LOGS_DIR — where to write per-project build logs (default: build_logs/)

set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
MAX_PARALLEL="${MAX_PARALLEL:-8}"
BUILD_LOGS_DIR="${BUILD_LOGS_DIR:-${BASE_DIR}/build_logs}"
mkdir -p "${BUILD_LOGS_DIR}"

CLASSIC_GAMES="RaylibBattleCity RaylibMinesweeper RaylibContra1987Lite \
               RaylibSuperMario1985Lite RaylibFighter97Lite RaylibJackal1988Lite \
               RaylibBomberman1983Lite"

# ── Discover projects ─────────────────────────────────────────────────────────
if [[ $# -gt 0 ]]; then
    # Explicit list passed as arguments
    PROJECTS=()
    for name in "$@"; do
        d="${BASE_DIR}/${name}"
        [[ -f "${d}/gradlew" ]] && PROJECTS+=("$d")
    done
else
    PROJECTS=()
    while IFS= read -r d; do
        name=$(basename "$d")
        [[ ! -f "${d}/gradlew" ]] && continue
        if [[ "$name" == *2026 ]] || [[ " $CLASSIC_GAMES " == *" $name "* ]]; then
            PROJECTS+=("$d")
        fi
    done < <(find "${BASE_DIR}" -maxdepth 1 -mindepth 1 -type d | sort)
fi

echo "Building ${#PROJECTS[@]} projects (MAX_PARALLEL=${MAX_PARALLEL})..."

# ── Ensure local.properties ───────────────────────────────────────────────────
for proj_dir in "${PROJECTS[@]}"; do
    lp="${proj_dir}/local.properties"
    [[ ! -f "$lp" ]] && echo "sdk.dir=${ANDROID_HOME}" > "$lp"
done

# ── Parallel builds ───────────────────────────────────────────────────────────
FAIL_FAST="${FAIL_FAST:-false}"
RESULTS_DIR=$(mktemp -d)
FAIL_FLAG="${RESULTS_DIR}/.fail_fast"
PIDS=()

for proj_dir in "${PROJECTS[@]}"; do
    # If fail-fast triggered, stop launching new builds
    if [[ "${FAIL_FAST}" == "true" ]] && [[ -f "${FAIL_FLAG}" ]]; then
        break
    fi

    proj_name=$(basename "${proj_dir}")
    (
        log="${BUILD_LOGS_DIR}/${proj_name}.log"
        if cd "${proj_dir}" && GRADLE_USER_HOME="${RESULTS_DIR}/.gradle_${proj_name}" \
                ./gradlew assembleDebug --no-daemon -q \
                >"${log}" 2>&1; then
            echo "PASS" > "${RESULTS_DIR}/${proj_name}"
        else
            echo "FAIL" > "${RESULTS_DIR}/${proj_name}"
            if [[ "${FAIL_FAST}" == "true" ]]; then
                touch "${FAIL_FLAG}"
            fi
        fi
    ) &
    PIDS+=($!)

    while (( $(jobs -rp | wc -l) >= MAX_PARALLEL )); do
        # Check fail-fast between polls
        if [[ "${FAIL_FAST}" == "true" ]] && [[ -f "${FAIL_FLAG}" ]]; then
            break
        fi
        sleep 1
    done
done

for pid in "${PIDS[@]}"; do wait "${pid}" || true; done

# ── Report ────────────────────────────────────────────────────────────────────
PASS=0; FAIL=0; FAIL_NAMES=()
for proj_dir in "${PROJECTS[@]}"; do
    proj_name=$(basename "${proj_dir}")
    result=$(cat "${RESULTS_DIR}/${proj_name}" 2>/dev/null || echo SKIP)
    if [[ "$result" == "PASS" ]]; then
        ((PASS++)) || true
    elif [[ "$result" == "FAIL" ]]; then
        ((FAIL++)) || true
        FAIL_NAMES+=("$proj_name")
    fi
done
rm -rf "${RESULTS_DIR}"

echo ""
echo "Build complete: ${PASS} PASS, ${FAIL} FAIL out of ${#PROJECTS[@]}"
if (( ${#FAIL_NAMES[@]} > 0 )); then
    echo "Failed projects:"
    printf '  %s\n' "${FAIL_NAMES[@]}"
fi

(( FAIL == 0 ))   # exit 0 only if all passed
