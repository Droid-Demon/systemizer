#!/system/bin/sh

MODPATH=${0%/*}

# Set permissions
set_perm_recursive $MODPATH 0 0 0755 0644
set_perm $MODPATH/service.sh 0 0 0755
set_perm_recursive $MODPATH/scripts 0 0 0755 0755
set_perm_recursive $MODPATH/webroot/cgi-bin 0 0 0755 0755

# Create necessary directories
mkdir -p $MODPATH/system/priv-app
mkdir -p $MODPATH/data

# Create data file to store converted apps list
touch $MODPATH/data/converted_apps.txt

# Set up WebUI port file
echo "9876" > $MODPATH/data/webui_port.txt

ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ui_print " User to System App Converter"
ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ui_print " "
ui_print "✓ Module installed successfully"
ui_print " "
ui_print "📱 Access WebUI at:"
ui_print "   http://localhost:9876"
ui_print " "
ui_print "⚠️  Reboot required to apply changes"
ui_print " "
ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"