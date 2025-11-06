#!/system/bin/sh

MODDIR=${0%/*}

# Wait for boot to complete
until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 1
done

# Additional wait for system stability
sleep 5

# Create API handler script
create_api_handler() {
    cat > $MODDIR/webroot/api.sh << 'APIEOF'
#!/system/bin/sh

MODDIR="/data/adb/modules/user_to_system_converter"

# Parse query string
ACTION=""
PACKAGE=""

if [ -n "$QUERY_STRING" ]; then
    for param in $(echo "$QUERY_STRING" | tr '&' '\n'); do
        key=$(echo "$param" | cut -d'=' -f1)
        value=$(echo "$param" | cut -d'=' -f2 | sed 's/%2E/./g' | sed 's/%2F/\//g' | sed 's/+/ /g')
        
        case "$key" in
            action) ACTION="$value" ;;
            package) PACKAGE="$value" ;;
        esac
    done
fi

echo "Content-Type: application/json"
echo ""

case "$ACTION" in
    list_user)
        CONVERTED_FILE="$MODDIR/data/converted_apps.txt"
        CONVERTED_PKGS=""
        if [ -f "$CONVERTED_FILE" ]; then
            while IFS='|' read -r pkg label; do
                CONVERTED_PKGS="$CONVERTED_PKGS|$pkg"
            done < "$CONVERTED_FILE"
        fi
        
        echo "["
        FIRST=1
        pm list packages -3 2>/dev/null | while IFS=: read -r _ pkg; do
            pkg=$(echo "$pkg" | tr -d '\r\n ')
            [ -z "$pkg" ] && continue
            
            case "$CONVERTED_PKGS" in
                *"|$pkg"*) continue ;;
            esac
            
            label=$(echo "$pkg" | awk -F. '{print $NF}')
            
            if [ $FIRST -eq 0 ]; then
                echo ","
            fi
            FIRST=0
            
            echo -n "{\"package\":\"$pkg\",\"label\":\"$label\"}"
        done
        echo ""
        echo "]"
        ;;
        
    list_converted)
        CONVERTED_FILE="$MODDIR/data/converted_apps.txt"
        
        if [ ! -f "$CONVERTED_FILE" ] || [ ! -s "$CONVERTED_FILE" ]; then
            echo "[]"
            exit 0
        fi
        
        echo "["
        FIRST=1
        while IFS='|' read -r pkg label; do
            pkg=$(echo "$pkg" | tr -d '\r\n ')
            label=$(echo "$label" | tr -d '\r\n ')
            [ -z "$pkg" ] && continue
            
            if [ $FIRST -eq 0 ]; then
                echo ","
            fi
            FIRST=0
            
            echo -n "{\"package\":\"$pkg\",\"label\":\"$label\"}"
        done < "$CONVERTED_FILE"
        echo ""
        echo "]"
        ;;
        
    convert)
        if [ -z "$PACKAGE" ]; then
            echo "{\"success\":false,\"message\":\"No package specified\"}"
            exit 1
        fi
        
        RESULT=$(sh $MODDIR/scripts/mount_apps.sh "$PACKAGE" 2>&1)
        
        if echo "$RESULT" | grep -q "SUCCESS"; then
            echo "{\"success\":true,\"message\":\"App converted successfully\"}"
        else
            MSG=$(echo "$RESULT" | grep "ERROR" | sed 's/ERROR: //')
            [ -z "$MSG" ] && MSG="Unknown error"
            echo "{\"success\":false,\"message\":\"$MSG\"}"
        fi
        ;;
        
    restore)
        if [ -z "$PACKAGE" ]; then
            echo "{\"success\":false,\"message\":\"No package specified\"}"
            exit 1
        fi
        
        RESULT=$(sh $MODDIR/scripts/restore_apps.sh "$PACKAGE" 2>&1)
        
        if echo "$RESULT" | grep -q "SUCCESS"; then
            echo "{\"success\":true,\"message\":\"App restored successfully\"}"
        else
            MSG=$(echo "$RESULT" | grep "ERROR" | sed 's/ERROR: //')
            [ -z "$MSG" ] && MSG="Unknown error"
            echo "{\"success\":false,\"message\":\"$MSG\"}"
        fi
        ;;
        
    *)
        echo "{\"error\":\"Invalid action\"}"
        ;;
esac
APIEOF

    chmod 755 $MODDIR/webroot/api.sh
}

# Start WebUI server
start_webui() {
    PORT=$(cat $MODDIR/data/webui_port.txt 2>/dev/null || echo "9876")
    
    # Kill any existing instance
    pkill -f "httpd.*$PORT"
    
    # Create API handler
    create_api_handler
    
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
        $BUSYBOX httpd -f -p $PORT -h $MODDIR/webroot >/dev/null 2>&1 &
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
