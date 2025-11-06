#!/system/bin/sh

echo "Content-Type: application/json"
echo "Access-Control-Allow-Origin: *"
echo ""

CONVERTED_FILE="/data/adb/modules/user_to_system_converter/data/converted_apps.txt"

# Use su to read the file
if ! su -c "test -f $CONVERTED_FILE" 2>/dev/null || ! su -c "test -s $CONVERTED_FILE" 2>/dev/null; then
    echo "[]"
    exit 0
fi

echo "["
FIRST=1
su -c "cat $CONVERTED_FILE" 2>/dev/null | while IFS='|' read -r pkg label; do
    pkg=$(echo "$pkg" | tr -d '\r\n ')
    label=$(echo "$label" | tr -d '\r\n ')
    
    [ -z "$pkg" ] && continue
    
    # Add comma separator except for first item
    if [ $FIRST -eq 0 ]; then
        echo ","
    fi
    FIRST=0
    
    # Output JSON - escape any special characters
    pkg_clean=$(echo "$pkg" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
    label_clean=$(echo "$label" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
    echo -n "{\"package\":\"$pkg_clean\",\"label\":\"$label_clean\"}"
done
echo ""
echo "]"