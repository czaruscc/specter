#!/system/bin/sh
MODDIR=${0%/*}
. "$MODDIR/../lib/common.sh"
. "$MODDIR/../lib/paths.sh"
. "$MODDIR/../lib/urls.sh"

log "KEYBOX" "Start"

if [ ! -d "/data/adb/tricky_store" ]; then
  log "KEYBOX" "Warning: Tricky Store data directory not found"
  exit 0
fi

if [ -f "$TARGET_FILE" ] && [ ! -f "$BACKUP_FILE" ]; then
  cp "$TARGET_FILE" "$BACKUP_FILE"
fi

TEMP_FILE="$TRICKY_DIR/keybox.tmp"
download "$KEYBOX_URL" > "$TEMP_FILE" || {
  log "KEYBOX" "Error: Download failed"
  rm -f "$TEMP_FILE"
  [ -f "$BACKUP_FILE" ] && cp "$BACKUP_FILE" "$TARGET_FILE"
  exit 1
}

if ! base64 -d "$TEMP_FILE" > "$TARGET_FILE" 2>/dev/null; then
  log "KEYBOX" "Error: Base64 decode failed"
  rm -f "$TEMP_FILE"
  [ -f "$BACKUP_FILE" ] && cp "$BACKUP_FILE" "$TARGET_FILE"
  exit 1
fi

rm -f "$TEMP_FILE"
log "KEYBOX" "Finish"
exit 0
