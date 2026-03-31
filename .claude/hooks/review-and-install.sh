#!/bin/bash
# Claude Code Hook: Review code + Build Release + Install to iPhone
# Triggered on Stop event after Claude finishes responding
#
# This script:
# 1. Checks if any Swift files were recently modified
# 2. Reviews code for rule violations
# 3. Builds a Release build for the connected iPhone
# 4. Installs the app on the iPhone

set -euo pipefail

# --- Configuration ---
PROJECT_DIR="/Users/maitrungkien/Desktop/project/Quan Ly Chi Tieu"
XCODEPROJ="$PROJECT_DIR/QuanLyChiTieu.xcodeproj"
SCHEME="QuanLyChiTieu"
DERIVED_DATA="$PROJECT_DIR/.build/DerivedData"
DEVICE_ID="6308D40C-1BEC-5B2A-88EC-687026979B79"
BUILD_DEVICE_ID="00008120-0016116A1103C01E"
DEVICE_NAME="Kiên's iPhone"
LOG_FILE="$PROJECT_DIR/.build/hook-log.txt"

mkdir -p "$PROJECT_DIR/.build"

# --- Helpers ---
log() {
    echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

notify() {
    osascript -e "display notification \"$1\" with title \"Quản Lý Chi Tiêu\"" 2>/dev/null || true
}

# --- Step 0: Check if Swift files were modified recently (last 2 minutes) ---
MODIFIED_SWIFT=$(find "$PROJECT_DIR/QuanLyChiTieu" -name "*.swift" -mmin -2 2>/dev/null | head -20)

if [ -z "$MODIFIED_SWIFT" ]; then
    # No recent Swift changes — skip build
    exit 0
fi

MODIFIED_COUNT=$(echo "$MODIFIED_SWIFT" | wc -l | tr -d ' ')
log "=== Hook triggered: $MODIFIED_COUNT Swift file(s) modified ==="

# --- Step 1: Code Review ---
log "--- Step 1: Code Review ---"
REVIEW_ISSUES=0

while IFS= read -r file; do
    filename=$(basename "$file")

    # Check file length (max 300 lines per rule.md)
    line_count=$(wc -l < "$file" | tr -d ' ')
    if [ "$line_count" -gt 300 ]; then
        log "WARNING: $filename has $line_count lines (max 300)"
        REVIEW_ISSUES=$((REVIEW_ISSUES + 1))
    fi

    # Check for force unwraps (!)
    if grep -n '[^!]![^=!]' "$file" 2>/dev/null | grep -v '//' | grep -v 'TODO' | grep -qv '#Preview'; then
        force_unwrap_count=$(grep -c '[^!]![^=!]' "$file" 2>/dev/null || echo 0)
        if [ "$force_unwrap_count" -gt 0 ]; then
            log "CHECK: $filename may have force unwraps ($force_unwrap_count matches — verify manually)"
        fi
    fi

    # Check for try! (forbidden)
    if grep -qn 'try!' "$file" 2>/dev/null; then
        log "ERROR: $filename contains try! (forbidden in production)"
        REVIEW_ISSUES=$((REVIEW_ISSUES + 1))
    fi

    # Check for print() (should use os.Logger)
    if grep -qn 'print(' "$file" 2>/dev/null; then
        if ! grep -q '#Preview' "$file" 2>/dev/null; then
            log "WARNING: $filename uses print() — prefer os.Logger"
        fi
    fi

    # Check for ObservableObject (should use @Observable)
    if grep -qn 'ObservableObject' "$file" 2>/dev/null; then
        log "ERROR: $filename uses ObservableObject — must use @Observable"
        REVIEW_ISSUES=$((REVIEW_ISSUES + 1))
    fi

    # Check for @Published (should use @Observable)
    if grep -qn '@Published' "$file" 2>/dev/null; then
        log "ERROR: $filename uses @Published — must use @Observable"
        REVIEW_ISSUES=$((REVIEW_ISSUES + 1))
    fi

done <<< "$MODIFIED_SWIFT"

if [ "$REVIEW_ISSUES" -gt 0 ]; then
    log "Review found $REVIEW_ISSUES issue(s) — building anyway"
    notify "Code review: $REVIEW_ISSUES issue(s) found"
else
    log "Code review passed — no issues found"
fi

# --- Step 2: Build Release ---
log "--- Step 2: Building Release for $DEVICE_NAME ---"
notify "Building release for $DEVICE_NAME..."

BUILD_LOG="$PROJECT_DIR/.build/build-log.txt"

xcodebuild \
    -project "$XCODEPROJ" \
    -scheme "$SCHEME" \
    -configuration Release \
    -destination "platform=iOS,id=$BUILD_DEVICE_ID" \
    -derivedDataPath "$DERIVED_DATA" \
    -allowProvisioningUpdates \
    -quiet \
    build 2>&1 | tail -20 > "$BUILD_LOG"

BUILD_EXIT=${PIPESTATUS[0]}

if [ "$BUILD_EXIT" -ne 0 ]; then
    log "BUILD FAILED (exit $BUILD_EXIT)"
    notify "Build FAILED — check .build/build-log.txt"
    cat "$BUILD_LOG" >> "$LOG_FILE"
    exit 0  # Exit 0 so Claude is not blocked
fi

log "Build succeeded"

# --- Step 3: Find the .app bundle ---
APP_PATH=$(find "$DERIVED_DATA/Build/Products/Release-iphoneos" -name "*.app" -maxdepth 1 2>/dev/null | head -1)

if [ -z "$APP_PATH" ]; then
    log "ERROR: Could not find .app bundle in DerivedData"
    notify "Install failed — .app not found"
    exit 0
fi

log "Found app: $APP_PATH"

# --- Step 4: Install to iPhone ---
log "--- Step 3: Installing to $DEVICE_NAME ---"
notify "Installing to $DEVICE_NAME..."

xcrun devicectl device install app \
    --device "$DEVICE_ID" \
    "$APP_PATH" 2>&1 | tee -a "$LOG_FILE"

INSTALL_EXIT=${PIPESTATUS[0]}

if [ "$INSTALL_EXIT" -ne 0 ]; then
    log "INSTALL FAILED (exit $INSTALL_EXIT)"
    notify "Install FAILED — check .build/hook-log.txt"
    exit 0
fi

log "=== Successfully installed to $DEVICE_NAME ==="
notify "Installed on $DEVICE_NAME"

exit 0
