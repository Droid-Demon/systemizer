#!/system/bin/sh

MODDIR=${0%/*}

# Unmount all converted apps
if [ -f "$MODDIR/data/converted_apps.txt" ]; then
    while IFS='|' read -r pkg_name app_name; do
        [ -z "$pkg_name" ] && continue
        
        TARGET_DIR="/system/priv-app/$pkg_name"
        
        # Unmount if mounted
        if mount | grep -q "$TARGET_DIR"; then
            umount "$TARGET_DIR"
        fi
        
        # Remove target directory if empty
        if [ -d "$TARGET_DIR" ]; then
            rmdir "$TARGET_DIR" 2>/dev/null
        fi
    done < "$MODDIR/data/converted_apps.txt"
fi

# Kill WebUI server
PORT=$(cat $MODDIR/data/webui_port.txt 2>/dev/null || echo "9876")
pkill -f "httpd.*$PORT"

# Clean up
rm -rf $MODDIR/system/priv-app/*
rm -f $MODDIR/data/converted_apps.txt

echo "User to System App Converter uninstalled successfully"
echo "All apps have been restored to their original state"