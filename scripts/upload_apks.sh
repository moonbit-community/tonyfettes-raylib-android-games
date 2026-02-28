#!/usr/bin/env bash
# upload_apks.sh — Upload built game APKs to S3.
#
# Usage:
#   bash scripts/upload_apks.sh                          # upload all built game APKs
#   bash scripts/upload_apks.sh Raylib{A,B}* RaylibFoo  # upload specific projects
#
# Environment:
#   S3_BUCKET   — target bucket (default: moonbit-raylib-android-games)
#   AWS_REGION  — AWS region    (default: us-west-2)

set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
S3_BUCKET="${S3_BUCKET:-moonbit-raylib-android-games}"
AWS_REGION="${AWS_REGION:-us-west-2}"

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

echo "Uploading ${#PROJECTS[@]} projects to s3://${S3_BUCKET} (${AWS_REGION})..."

# ── Upload ────────────────────────────────────────────────────────────────────
uploaded=0; skipped=0

for d in "${PROJECTS[@]}"; do
    name=$(basename "$d")
    apk="${d}/app/build/outputs/apk/debug/app-debug.apk"
    if [[ -f "$apk" ]]; then
        echo "  ${name}.apk"
        aws s3 cp "$apk" "s3://${S3_BUCKET}/${name}.apk" \
            --region "${AWS_REGION}" \
            --content-type "application/vnd.android.package-archive" \
            --no-progress
        ((uploaded++)) || true
    else
        echo "  SKIP (no APK built): ${name}"
        ((skipped++)) || true
    fi
done

echo ""
echo "Upload complete: ${uploaded} uploaded, ${skipped} skipped."
