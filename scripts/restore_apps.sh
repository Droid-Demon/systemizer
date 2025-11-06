#!/system/bin/sh

MODDIR="/data/adb/modules/user_to_system_converter"

# Function to restore system app back to user app
restore_to_user() {
    PKG_NAME=$1
    
    # Check if app is in converted list
    if ! grep -q "^$PKG_NAME|" "$MODDIR/data/converted_apps.txt" 2>/dev/null; then
        echo "ERROR: App not found in converted list"
        return 1
    fi
    
    # Unmount if mounted
    TARGET_DIR="/system/priv-app/$PKG_NAME"
    if mount | grep -q "$TARGET_DIR"; then
        umount "$TARGET_DIR"
    fi
    
    # Remove target directory if empty
    if [ -d "$TARGET_DIR" ]; then
        rmdir "$TARGET_DIR" 2>/dev/null
    fi
    
    # Remove app directory from module
    APP_DIR="$MODDIR/system/priv-app/$PKG_NAME"
    if [ -d "$APP_DIR" ]; then
        rm -rf "$APP_DIR"
    fi
    
    # Remove from converted list
    grep -v "^$PKG_NAME|" "$MODDIR/data/converted_apps.txt" > "$MODDIR/data/converted_apps.txt.tmp"
    mv "$MODDIR/data/converted_apps.txt.tmp" "$MODDIR/data/converted_apps.txt"
    
    echo "SUCCESS: $PKG_NAME restored to user app"
    return 0
}

# Main execution
if [ -z "$1" ]; then
    echo "ERROR: No package name provided"
    exit 1
fi

restore_to_user "$1"
