#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# batch_generate.sh
# Generates Android projects for all MoonBit raylib examples
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXAMPLES_DIR="$HOME/Workspace/moonbit/raylib/examples"
GENERATE_SCRIPT="$SCRIPT_DIR/generate_android_project.sh"

# --- Usage ---
usage() {
    cat <<'EOF'
Usage: ./batch_generate.sh [OPTIONS]

Options:
  --skip-existing    Skip examples that already have generated projects
  --dry-run          Preview without creating files
  --help             Show this help
EOF
    exit 0
}

# --- Parse arguments ---
SKIP_EXISTING=false
DRY_RUN=false
EXTRA_ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-existing) SKIP_EXISTING=true; shift ;;
        --dry-run) DRY_RUN=true; EXTRA_ARGS+=("--dry-run"); shift ;;
        --help) usage ;;
        -*) echo "Error: Unknown option $1"; usage ;;
        *) echo "Error: Unexpected argument $1"; usage ;;
    esac
done

# --- Exclusion list ---
# Examples that are already migrated manually or incompatible
declare -A EXCLUSIONS=(
    ["raylib_tank_1990"]="already migrated as RaylibBattleCity"
    ["raylib_minesweeper"]="already migrated as RaylibMinesweeper"
)

# --- Portrait orientation examples (heuristic) ---
# Most examples use landscape (800x450 or wider), these are known portrait ones
declare -A PORTRAIT_EXAMPLES=(
    # Add specific examples that should be portrait here
    # Most raylib examples default to landscape
)

# --- Counters ---
TOTAL=0
GENERATED=0
SKIPPED=0
EXCLUDED=0
FAILED=0
FAILED_LIST=()

echo "=========================================="
echo "  Batch Android Project Generation"
echo "=========================================="
echo ""
echo "Examples dir: $EXAMPLES_DIR"
echo "Output dir:   $SCRIPT_DIR"
echo ""

# --- Convert to PascalCase (must match generate script) ---
to_pascal_case() {
    echo "$1" | sed 's/_/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1' | sed 's/ //g'
}

# --- Process each example ---
for example_path in "$EXAMPLES_DIR"/*/; do
    # Skip if not a directory
    [[ -d "$example_path" ]] || continue

    example_dir=$(basename "$example_path")

    # Skip non-example directories (e.g., target, .mooncakes)
    [[ -f "$example_path/moon.pkg" ]] || continue

    TOTAL=$((TOTAL + 1))

    # Check exclusion list
    if [[ -v "EXCLUSIONS[$example_dir]" ]]; then
        echo "[EXCLUDED] $example_dir (${EXCLUSIONS[$example_dir]})"
        EXCLUDED=$((EXCLUDED + 1))
        continue
    fi

    # Check if project already exists
    PROJECT_NAME=$(to_pascal_case "$example_dir")
    if [[ -d "$SCRIPT_DIR/$PROJECT_NAME" ]]; then
        if $SKIP_EXISTING; then
            echo "[SKIPPED]  $example_dir -> $PROJECT_NAME (already exists)"
            SKIPPED=$((SKIPPED + 1))
            continue
        elif ! $DRY_RUN; then
            echo "[SKIPPED]  $example_dir -> $PROJECT_NAME (already exists)"
            SKIPPED=$((SKIPPED + 1))
            continue
        fi
    fi

    # Determine orientation
    ORIENTATION="landscape"
    if [[ -v "PORTRAIT_EXAMPLES[$example_dir]" ]]; then
        ORIENTATION="portrait"
    fi

    # Generate project
    echo "[GENERATE] $example_dir -> $PROJECT_NAME"
    GEN_OUTPUT=$("$GENERATE_SCRIPT" "$example_dir" --orientation "$ORIENTATION" "${EXTRA_ARGS[@]}" 2>&1) && GEN_RC=0 || GEN_RC=$?
    echo "$GEN_OUTPUT" | sed 's/^/  /'
    if [[ $GEN_RC -eq 0 ]]; then
        GENERATED=$((GENERATED + 1))
    else
        echo "  [FAILED] $example_dir (exit code $GEN_RC)"
        FAILED=$((FAILED + 1))
        FAILED_LIST+=("$example_dir")
    fi

    echo ""
done

# --- Summary ---
echo "=========================================="
echo "  Summary"
echo "=========================================="
echo "  Total examples: $TOTAL"
echo "  Generated:      $GENERATED"
echo "  Excluded:       $EXCLUDED"
echo "  Skipped:        $SKIPPED"
echo "  Failed:         $FAILED"

if [[ ${#FAILED_LIST[@]} -gt 0 ]]; then
    echo ""
    echo "  Failed examples:"
    for f in "${FAILED_LIST[@]}"; do
        echo "    - $f"
    done
fi

echo "=========================================="
