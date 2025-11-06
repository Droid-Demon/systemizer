#!/system/bin/sh

MODDIR=${0%/*}

# Wait for boot to complete
until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 1
done

# Additional wait for system stability
sleep 5

# Start WebUI server with CGI support (as root)
start_webui() {
    PORT=$(cat $MODDIR/data/webui_port.txt 2>/dev/null || echo "9876")
    
    # Kill any existing instance
    pkill -f "httpd.*$PORT"
    
    cd $MODDIR/webroot
    
    # Find busybox
    BUSYBOX=""
    if [ -x "/system/xbin/busybox" ]; then
        BUSYBOX="/system/xbin/busybox"
    elif [ -x "/system/bin/busybox" ]; then
        BUSYBOX="/system/bin/busybox"
    elif command -v busybox >/dev/null 2>&1; then
        BUSYBOX="busybox"
    fi
    
    if [ -n "$BUSYBOX" ]; then
        # Run httpd as root using su
        su -c "$BUSYBOX httpd -f -p $PORT -h $MODDIR/webroot" >/dev/null 2>&1 &
    else
        echo "BusyBox not found! WebUI will not start."
    fi
}

# Mount converted apps
mount_apps() {
    if [ -f "$MODDIR/data/converted_apps.txt" ]; then
        while IFS='|' read -r pkg_name app_name; do
            [ -z "$pkg_name" ] && continue
            
            SOURCE_DIR="$MODDIR/system/priv-app/$pkg_name"
            TARGET_DIR="/system/priv-app/$pkg_name"
            
            if [ -d "$SOURCE_DIR" ]; then
                mkdir -p "$TARGET_DIR"
                mount -o bind "$SOURCE_DIR" "$TARGET_DIR"
            fi
        done < "$MODDIR/data/converted_apps.txt"
    fi
}

# Execute mounting
mount_apps

# Start WebUI
start_webui