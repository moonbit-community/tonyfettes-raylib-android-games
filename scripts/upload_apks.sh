#!/usr/bin/env bash
# upload_apks.sh — Upload all built APKs to S3.
#
# Usage:
#   bash scripts/upload_apks.sh
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

uploaded=0; skipped=0

while IFS= read -r d; do
    name=$(basename "$d")
    [[ ! -f "${d}/gradlew" ]] && continue
    if [[ "$name" == *2026 ]] || [[ " $CLASSIC_GAMES " == *" $name "* ]]; then
        apk="${d}/app/build/outputs/apk/debug/app-debug.apk"
        if [[ -f "$apk" ]]; then
            echo "Uploading ${name}.apk ..."
            aws s3 cp "$apk" "s3://${S3_BUCKET}/${name}.apk" \
                --region "${AWS_REGION}" \
                --content-type "application/vnd.android.package-archive" \
                --no-progress
            ((uploaded++)) || true
        else
            echo "SKIP (no APK): ${name}"
            ((skipped++)) || true
        fi
    fi
done < <(find "${BASE_DIR}" -maxdepth 1 -mindepth 1 -type d | sort)

echo ""
echo "Upload complete: ${uploaded} uploaded, ${skipped} skipped (no APK built)."
