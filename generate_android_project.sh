#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# generate_android_project.sh
# Generates an Android project from a MoonBit raylib example
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/_template"
EXAMPLES_DIR="$HOME/Workspace/moonbit/raylib/examples"

# --- Usage ---
usage() {
    cat <<'EOF'
Usage: ./generate_android_project.sh <example_dir_name> [OPTIONS]

Options:
  --orientation landscape|portrait   Set screen orientation (default: landscape)
  --dry-run                          Preview without creating files
  --help                             Show this help

Examples:
  ./generate_android_project.sh raylib_core_basic_window
  ./generate_android_project.sh raylib_minesweeper --orientation portrait
  ./generate_android_project.sh raygui_demo --dry-run
EOF
    exit 0
}

# --- Parse arguments ---
EXAMPLE_DIR=""
ORIENTATION="landscape"
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --orientation) ORIENTATION="$2"; shift 2 ;;
        --dry-run) DRY_RUN=true; shift ;;
        --help) usage ;;
        -*) echo "Error: Unknown option $1"; usage ;;
        *) EXAMPLE_DIR="$1"; shift ;;
    esac
done

if [[ -z "$EXAMPLE_DIR" ]]; then
    echo "Error: No example directory name provided"
    usage
fi

# --- Validate example exists ---
EXAMPLE_PATH="$EXAMPLES_DIR/$EXAMPLE_DIR"
if [[ ! -d "$EXAMPLE_PATH" ]]; then
    echo "Error: Example directory not found: $EXAMPLE_PATH"
    exit 1
fi

# --- Derive variables from example directory name ---
# Convert underscore-separated name to PascalCase
# e.g. raylib_core_basic_window -> RaylibCoreBasicWindow
to_pascal_case() {
    echo "$1" | sed 's/_/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1' | sed 's/ //g'
}

# Convert to display name (Title Case with spaces)
# e.g. raylib_core_basic_window -> Raylib Core Basic Window
to_display_name() {
    echo "$1" | sed 's/_/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1'
}

# PACKAGE_ID: lowercase, strip underscores
PACKAGE_ID=$(echo "$EXAMPLE_DIR" | tr -d '_')
# PROJECT_NAME: PascalCase
PROJECT_NAME=$(to_pascal_case "$EXAMPLE_DIR")
# DISPLAY_NAME: Title Case with spaces
DISPLAY_NAME=$(to_display_name "$EXAMPLE_DIR")
# THEME_NAME: Theme. + PROJECT_NAME
THEME_NAME="Theme.${PROJECT_NAME}"
# MODULE_NAME: tonyfettes/ + PACKAGE_ID
MODULE_NAME="tonyfettes/${PACKAGE_ID}"

PROJECT_DIR="$SCRIPT_DIR/$PROJECT_NAME"

echo "=== Generating Android project ==="
echo "  Example:      $EXAMPLE_DIR"
echo "  Project:      $PROJECT_NAME"
echo "  Package ID:   $PACKAGE_ID"
echo "  Display Name: $DISPLAY_NAME"
echo "  Theme:        $THEME_NAME"
echo "  Module:       $MODULE_NAME"
echo "  Orientation:  $ORIENTATION"
echo "  Output:       $PROJECT_DIR"

if $DRY_RUN; then
    echo ""
    echo "[DRY RUN] Would create project at: $PROJECT_DIR"
    # Check what MoonBit files would be copied
    echo ""
    echo "  MoonBit files:"
    find "$EXAMPLE_PATH" -name "*.mbt" -not -name "*_test.mbt" -not -path "*/target/*" | sort | while read -r f; do
        echo "    $(basename "$f")"
    done
    # Check for resources
    if [[ -d "$EXAMPLE_PATH/resources" ]]; then
        echo "  Resources: YES ($(find "$EXAMPLE_PATH/resources" -type f | wc -l | tr -d ' ') files)"
    else
        echo "  Resources: NO"
    fi
    # Check for sub-packages
    SUB_PKG_COUNT=$(find "$EXAMPLE_PATH" -mindepth 2 -name "moon.pkg" -not -path "*/target/*" | wc -l | tr -d ' ')
    if [[ "$SUB_PKG_COUNT" -gt 0 ]]; then
        echo "  Sub-packages: $SUB_PKG_COUNT (will be flattened)"
    fi
    exit 0
fi

# --- Check if project already exists ---
if [[ -d "$PROJECT_DIR" ]]; then
    echo "Error: Project directory already exists: $PROJECT_DIR"
    exit 1
fi

# --- Step 1: Copy template ---
echo ""
echo "Step 1: Copying template..."
cp -R "$TEMPLATE_DIR" "$PROJECT_DIR"

# --- Step 2: Substitute placeholders in templated files ---
echo "Step 2: Substituting placeholders..."

# List of files that contain {{PLACEHOLDER}} tokens
TEMPLATED_FILES=(
    "settings.gradle.kts"
    "app/build.gradle.kts"
    "app/src/main/AndroidManifest.xml"
    "app/src/main/java/MainActivity.kt"
    "app/src/main/cpp/CMakeLists.txt"
    "app/src/main/res/values/strings.xml"
    "app/src/main/res/values/themes.xml"
    "app/src/main/res/values-night/themes.xml"
)

for file in "${TEMPLATED_FILES[@]}"; do
    filepath="$PROJECT_DIR/$file"
    if [[ -f "$filepath" ]]; then
        sed -i '' \
            -e "s|{{PACKAGE_ID}}|${PACKAGE_ID}|g" \
            -e "s|{{PROJECT_NAME}}|${PROJECT_NAME}|g" \
            -e "s|{{DISPLAY_NAME}}|${DISPLAY_NAME}|g" \
            -e "s|{{THEME_NAME}}|${THEME_NAME}|g" \
            -e "s|{{MODULE_NAME}}|${MODULE_NAME}|g" \
            -e "s|{{ORIENTATION}}|${ORIENTATION}|g" \
            "$filepath"
    fi
done

# --- Step 3: Create Java package directory and move MainActivity.kt ---
echo "Step 3: Setting up Java package..."
JAVA_PKG_DIR="$PROJECT_DIR/app/src/main/java/com/example/$PACKAGE_ID"
mkdir -p "$JAVA_PKG_DIR"
mv "$PROJECT_DIR/app/src/main/java/MainActivity.kt" "$JAVA_PKG_DIR/MainActivity.kt"

# --- Step 4: Create MoonBit directory and copy source files ---
echo "Step 4: Copying MoonBit sources..."
MOONBIT_DIR="$PROJECT_DIR/app/src/main/moonbit"
mkdir -p "$MOONBIT_DIR"

# Check if this is a sub-package example (has moon.pkg in subdirectories)
SUB_PKG_COUNT=$(find "$EXAMPLE_PATH" -mindepth 2 -name "moon.pkg" -not -path "*/target/*" | wc -l | tr -d ' ')

if [[ "$SUB_PKG_COUNT" -gt 0 ]]; then
    echo "  Sub-package example detected ($SUB_PKG_COUNT sub-packages) - flattening..."
    # Copy all .mbt files from all directories (excluding test files)
    find "$EXAMPLE_PATH" -name "*.mbt" -not -name "*_test.mbt" -not -path "*/target/*" | while read -r mbt_file; do
        cp "$mbt_file" "$MOONBIT_DIR/"
    done

    # Strip internal sub-package qualifiers (@pkgname. -> empty)
    # Collect sub-package directory names (these are internal package references)
    SUB_PKG_NAMES=()
    while IFS= read -r pkg_dir; do
        pkg_name=$(basename "$(dirname "$pkg_dir")")
        SUB_PKG_NAMES+=("$pkg_name")
    done < <(find "$EXAMPLE_PATH" -mindepth 2 -name "moon.pkg" -not -path "*/target/*")

    echo "  Stripping internal package qualifiers: ${SUB_PKG_NAMES[*]}"
    for pkg_name in "${SUB_PKG_NAMES[@]}"; do
        # Replace @pkgname. with empty string in all .mbt files
        find "$MOONBIT_DIR" -name "*.mbt" -exec sed -i '' "s/@${pkg_name}\.//g" {} +
    done
else
    # Flat example: copy all .mbt files from root
    find "$EXAMPLE_PATH" -maxdepth 1 -name "*.mbt" -not -name "*_test.mbt" | while read -r mbt_file; do
        cp "$mbt_file" "$MOONBIT_DIR/"
    done
fi

# --- Step 5: Generate moon.mod.json ---
echo "Step 5: Generating moon.mod.json..."
cat > "$MOONBIT_DIR/moon.mod.json" <<MOONMOD
{
  "name": "${MODULE_NAME}",
  "version": "0.1.0",
  "deps": {
    "tonyfettes/raylib": "0.1.0"
  },
  "preferred-target": "native"
}
MOONMOD

# --- Step 6: Generate moon.pkg ---
echo "Step 6: Generating moon.pkg..."

# Collect all unique external imports from all moon.pkg files in the example
# External = not starting with the examples module path (tonyfettes/raylib-examples/...)
IMPORTS=""

collect_imports() {
    local pkg_file="$1"
    if [[ -f "$pkg_file" ]]; then
        # Extract import lines: lines between "import {" and "}" that contain quoted strings
        # Filter out internal sub-package imports (tonyfettes/raylib-examples/...)
        awk '/^import \{/,/^\}/' "$pkg_file" | \
            grep '"' | \
            grep -v 'tonyfettes/raylib-examples/' | \
            sed 's/.*"\(.*\)".*/\1/' | \
            sort -u
    fi
}

# Collect from main moon.pkg
MAIN_IMPORTS=$(collect_imports "$EXAMPLE_PATH/moon.pkg")

# If sub-package example, also collect from all sub-package moon.pkg files
if [[ "$SUB_PKG_COUNT" -gt 0 ]]; then
    SUB_IMPORTS=$(find "$EXAMPLE_PATH" -mindepth 2 -name "moon.pkg" -not -path "*/target/*" -exec sh -c '
        for f; do
            awk "/^import \{/,/^\}/" "$f" | grep "\"" | grep -v "tonyfettes/raylib-examples/" | sed "s/.*\"\(.*\)\".*/\1/"
        done
    ' sh {} + | sort -u)
    ALL_IMPORTS=$(printf '%s\n%s' "$MAIN_IMPORTS" "$SUB_IMPORTS" | sort -u | grep -v '^$')
else
    ALL_IMPORTS=$(echo "$MAIN_IMPORTS" | sort -u | grep -v '^$')
fi

# Build the moon.pkg file
{
    echo 'import {'
    echo "$ALL_IMPORTS" | while read -r imp; do
        if [[ -n "$imp" ]]; then
            echo "  \"$imp\","
        fi
    done
    echo '}'
    echo ''
    echo 'options('
    echo '  "is-main": true,'
    echo ')'
} > "$MOONBIT_DIR/moon.pkg"

# --- Step 7: Copy resources ---
if [[ -d "$EXAMPLE_PATH/resources" ]]; then
    echo "Step 7: Copying resources..."
    ASSETS_DIR="$PROJECT_DIR/app/src/main/assets"
    mkdir -p "$ASSETS_DIR"
    cp -R "$EXAMPLE_PATH/resources" "$ASSETS_DIR/resources"
else
    echo "Step 7: No resources to copy."
fi

# --- Step 8: Run moon install ---
echo "Step 8: Running moon install..."
(cd "$MOONBIT_DIR" && moon install 2>&1) || {
    echo "Warning: moon install failed (dependencies may need manual resolution)"
}

echo ""
echo "=== Project generated successfully: $PROJECT_DIR ==="
