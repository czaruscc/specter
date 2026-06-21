#!/system/bin/sh
# Deploy module update from sdcard zip to /data/adb/modules/specter/
# Usage: su -c sh /sdcard/specter-update/deploy-module.sh [zip-path]
# If no zip path given, uses latest Specter-*.zip in the same directory

SRC="${1:-/sdcard/specter-update/Specter-*.zip}"
ZIP=$(ls $SRC 2>/dev/null | sort | tail -1)

if [ -z "$ZIP" ] || [ ! -f "$ZIP" ]; then
  echo "No zip found matching: $SRC"
  echo "Push the zip first: adb push Specter-*.zip /sdcard/specter-update/"
  exit 1
fi

MODULE_DIR="/data/adb/modules/specter"
echo "=== Deploying: $ZIP"
echo "Target: $MODULE_DIR"

# Backup config if it exists
if [ -f "$MODULE_DIR/config/specter.conf" ]; then
  cp "$MODULE_DIR/config/specter.conf" /data/local/tmp/specter.conf.bak
  echo "Backed up config"
fi

# Clean and extract
rm -rf "$MODULE_DIR"
mkdir -p "$MODULE_DIR"
unzip -o "$ZIP" -d "$MODULE_DIR" > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "ERROR: unzip failed"
  exit 1
fi

# Restore config
if [ -f /data/local/tmp/specter.conf.bak ]; then
  mkdir -p "$MODULE_DIR/config"
  cp /data/local/tmp/specter.conf.bak "$MODULE_DIR/config/specter.conf"
  rm /data/local/tmp/specter.conf.bak
  echo "Restored config"
fi

# Permissions
chmod -R 755 "$MODULE_DIR"
chmod -R 644 "$MODULE_DIR/webroot"/*.html "$MODULE_DIR/webroot/assets"/*.css "$MODULE_DIR/webroot/assets"/*.js 2>/dev/null || true

echo "=== Done! Module files updated at $MODULE_DIR"
echo "Hard-refresh the webui page to pick up changes."
