#!/system/bin/sh

echo "Content-Type: application/json"
echo "Access-Control-Allow-Origin: *"
echo ""

# Parse POST data
read POST_DATA

# Extract package name
PKG=$(echo "$POST_DATA" | sed 's/.*package=\([^&]*\).*/\1/' | sed 's/%2E/./g' | sed 's/%2F/\//g')

if [ -z "$PKG" ]; then
    echo "{\"success\":false,\"message\":\"No package specified\"}"
    exit 1
fi

# Execute restore script with root
RESULT=$(su -c "sh /data/adb/modules/user_to_system_converter/scripts/restore_apps.sh '$PKG'" 2>&1)

if echo "$RESULT" | grep -q "SUCCESS"; then
    echo "{\"success\":true,\"message\":\"App restored successfully\"}"
else
    MSG=$(echo "$RESULT" | grep "ERROR" | sed 's/ERROR: //')
    [ -z "$MSG" ] && MSG="Unknown error occurred"
    echo "{\"success\":false,\"message\":\"$MSG\"}"
fi
