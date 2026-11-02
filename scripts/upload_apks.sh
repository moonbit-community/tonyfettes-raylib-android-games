#!/usr/bin/env bash
# upload_apks.sh — Upload built game APKs to a rolling GitHub Release.
#
# Usage:
#   bash scripts/upload_apks.sh                          # upload all built game APKs
#   bash scripts/upload_apks.sh Raylib{A,B}* RaylibFoo  # upload specific projects
#   APK_DIR=/tmp/apks bash scripts/upload_apks.sh      # upload staged, named APKs
#
# Environment:
#   GH_REPO        — owner/repository (default: GITHUB_REPOSITORY or this repository)
#   RELEASE_TAG    — rolling release tag (default: android-games)
#   RELEASE_TARGET — initial tag target (default: GITHUB_SHA or main)
#   GH_TOKEN       — GitHub token (or authenticate with gh auth login)
#   APK_DIR        — directory of APKs already named <project>.apk (optional)

set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GH_REPO="${GH_REPO:-${GITHUB_REPOSITORY:-moonbit-community/tonyfettes-raylib-android-games}}"
RELEASE_TAG="${RELEASE_TAG:-android-games}"
RELEASE_TARGET="${RELEASE_TARGET:-${GITHUB_SHA:-main}}"

# CI and migrations can supply pre-collected APKs. Local builds are staged under
# their project names so Release assets never collide as app-debug.apk.
if [[ -z "${APK_DIR:-}" ]]; then
    APK_DIR=$(mktemp -d)
    trap 'rm -rf "$APK_DIR"' EXIT

    CLASSIC_GAMES="RaylibBattleCity RaylibMinesweeper RaylibContra1987Lite \
                   RaylibSuperMario1985Lite RaylibFighter97Lite RaylibJackal1988Lite \
                   RaylibBomberman1983Lite"

    # ── Collect project directories ───────────────────────────────────────────────
    PROJECTS=()
    if [[ $# -gt 0 ]]; then
        # Explicit list — accept bare names or full paths
        for arg in "$@"; do
            d="${BASE_DIR}/${arg##*/}"   # strip any leading path; resolve under BASE_DIR
            [[ -f "${d}/gradlew" ]] && PROJECTS+=("$d")
        done
    else
        # Auto-discover: all game projects (names ending in 2026 or classic ports)
        while IFS= read -r d; do
            name=$(basename "$d")
            [[ ! -f "${d}/gradlew" ]] && continue
            if [[ "$name" == *2026 ]] || [[ " $CLASSIC_GAMES " == *" $name "* ]]; then
                PROJECTS+=("$d")
            fi
        done < <(find "${BASE_DIR}" -maxdepth 1 -mindepth 1 -type d | sort)
    fi

    for d in "${PROJECTS[@]}"; do
        name=$(basename "$d")
        apk="${d}/app/build/outputs/apk/debug/app-debug.apk"
        if [[ -f "$apk" ]]; then
            cp "$apk" "${APK_DIR}/${name}.apk"
        else
            echo "  SKIP (no APK built): ${name}"
        fi
    done
fi

shopt -s nullglob
apks=("${APK_DIR}"/*.apk)
if (( ${#apks[@]} == 0 )); then
    echo "No APKs to upload, skipping."
    exit 0
fi

if ! gh release view "$RELEASE_TAG" --repo "$GH_REPO" >/dev/null 2>&1; then
    gh release create "$RELEASE_TAG" --repo "$GH_REPO" \
        --target "$RELEASE_TARGET" --draft \
        --title "Android Games" \
        --notes "Rolling collection of MoonBit + Raylib Android debug APKs. Individual assets are updated as builds complete; the tag identifies the initial publication, not every asset's source revision."
fi

echo "Uploading ${#apks[@]} APKs to ${GH_REPO} release ${RELEASE_TAG}..."
for apk in "${apks[@]}"; do
    echo "  $(basename "$apk")"
    gh release upload "$RELEASE_TAG" "$apk" --repo "$GH_REPO" --clobber
done

# A new release stays private until every upload succeeds. A failed upload can
# be retried with the same tag. Existing releases retain other games' assets.
is_draft=$(gh release view "$RELEASE_TAG" --repo "$GH_REPO" --json isDraft --jq .isDraft)
if [[ "$is_draft" == "true" ]]; then
    gh release edit "$RELEASE_TAG" --repo "$GH_REPO" --draft=false --latest
fi

echo ""
echo "Upload complete: ${#apks[@]} uploaded."
