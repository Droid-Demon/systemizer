#!/system/bin/sh

MODDIR="/data/adb/modules/user_to_system_converter"

# Function to convert user app to system app
convert_to_system() {
    PKG_NAME=$1
    
    # Get app info
    APP_PATH=$(pm path "$PKG_NAME" | head -n 1 | cut -d':' -f2)
    
    if [ -z "$APP_PATH" ]; then
        echo "ERROR: Package not found"
        return 1
    fi
    
    # Check if already converted
    if grep -q "^$PKG_NAME|" "$MODDIR/data/converted_apps.txt" 2>/dev/null; then
        echo "ERROR: App already converted"
        return 1
    fi
    
    # Get app label (simplified - just use package name)
    APP_LABEL=$(echo "$PKG_NAME" | awk -F. '{print $NF}')
    
    # Create directory structure
    APP_DIR="$MODDIR/system/priv-app/$PKG_NAME"
    mkdir -p "$APP_DIR"
    
    # Copy APK
    cp "$APP_PATH" "$APP_DIR/$PKG_NAME.apk"
    
    # Set permissions
    chmod 644 "$APP_DIR/$PKG_NAME.apk"
    chown 0:0 "$APP_DIR/$PKG_NAME.apk"
    
    # Copy lib directory if exists
    LIB_PATH=$(dirname "$APP_PATH")/lib
    if [ -d "$LIB_PATH" ]; then
        cp -r "$LIB_PATH" "$APP_DIR/"
        chmod -R 755 "$APP_DIR/lib"
        chown -R 0:0 "$APP_DIR/lib"
    fi
    
    # Add to converted list
    echo "$PKG_NAME|$APP_LABEL" >> "$MODDIR/data/converted_apps.txt"
    
    # Create magic mount
    TARGET_DIR="/system/priv-app/$PKG_NAME"
    mkdir -p "$TARGET_DIR"
    mount -o bind "$APP_DIR" "$TARGET_DIR"
    
    echo "SUCCESS: $PKG_NAME converted to system app"
    return 0
}

# Main execution
if [ -z "$1" ]; then
    echo "ERROR: No package name provided"
    exit 1
fi

convert_to_system "$1"