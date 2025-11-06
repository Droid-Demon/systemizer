#!/system/bin/sh

echo "Content-Type: application/json"
echo "Access-Control-Allow-Origin: *"
echo ""

# Get converted apps to exclude them
CONVERTED_FILE="/data/adb/modules/user_to_system_converter/data/converted_apps.txt"
CONVERTED_PKGS=""
if [ -f "$CONVERTED_FILE" ]; then
    while IFS='|' read -r pkg label; do
        CONVERTED_PKGS="$CONVERTED_PKGS|$pkg"
    done < "$CONVERTED_FILE"
fi

# Use su to run pm command as root
echo "["
FIRST=1

su -c "pm list packages -3" 2>/dev/null | while IFS=: read -r _ pkg; do
    pkg=$(echo "$pkg" | tr -d '\r\n ')
    
    # Skip if empty
    [ -z "$pkg" ] && continue
    
    # Skip if already converted
    case "$CONVERTED_PKGS" in
        *"|$pkg"*) continue ;;
    esac
    
    # Get app label - just use the last part of package name (simpler and no errors)
    label=$(echo "$pkg" | awk -F. '{print $NF}')
    
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