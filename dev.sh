#!/bin/bash
# Clipse dev mode — watches sources, rebuilds + relaunches on change
# Usage: ./dev.sh
# Requires: fswatch  →  brew install fswatch

set -e

PROJECT="Clipse.xcodeproj"
SCHEME="Clipse"
CONFIG="Debug"

# Resolve built app path once
APP_PATH=$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" \
    -configuration "$CONFIG" -showBuildSettings 2>/dev/null \
    | awk '/BUILT_PRODUCTS_DIR/{print $3}')"/Clipse.app"

if ! command -v fswatch &>/dev/null; then
    echo "fswatch not found. Install with: brew install fswatch"
    exit 1
fi

build_and_run() {
    echo ""
    echo "$(date '+%H:%M:%S')  ▸ Changed — building..."

    # Incremental build (only recompiles changed files, usually 3-8s)
    if xcodebuild -project "$PROJECT" -scheme "$SCHEME" \
        -configuration "$CONFIG" build \
        2>&1 | grep -E "error:|warning:|Build succeeded|BUILD SUCCEEDED|BUILD FAILED" \
             | grep -v "appintents" \
             | grep -v "warning: " ; then

        echo "✓  Build succeeded — relaunching Clipse"

        # Quit running instance gracefully
        osascript -e 'tell application "Clipse" to quit' 2>/dev/null || true
        sleep 0.4
        # Kill any leftover process
        pkill -x Clipse 2>/dev/null || true
        sleep 0.2

        open "$APP_PATH"
    else
        echo "✗  Build failed — fix errors above"
    fi
}

# Initial build + launch
build_and_run

echo ""
echo "👀  Watching Clipse/ for changes  (Ctrl+C to stop)"
echo ""

# Watch Swift source files only — ignore .xcodeproj churn
fswatch -o --include='\.swift$' --include='\.xcassets' \
    --exclude='.*\.xcodeproj.*' \
    Clipse/ \
| while read -r; do
    build_and_run
done
