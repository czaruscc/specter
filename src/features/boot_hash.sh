#!/system/bin/sh
MODDIR=${0%/*}
. "$MODDIR/../lib/common.sh"
. "$MODDIR/../lib/paths.sh"

log "BOOT_HASH" "Start"

_slot=$(getprop ro.boot.slot_suffix 2>/dev/null || echo "")

if [ -n "$_slot" ]; then
  _vbmeta="/dev/block/by-name/vbmeta$_slot"
else
  _vbmeta="/dev/block/by-name/vbmeta"
fi

_boot_hash=""

if [ -f "/sdcard/Specter/boot_hash" ] 2>/dev/null; then
  _boot_hash=$(tr -cd '0-9a-fA-F' < "/sdcard/Specter/boot_hash" 2>/dev/null)
  log "BOOT_HASH" "Using user config from /sdcard/Specter/boot_hash"
elif [ -f "$BOOT_HASH_FILE" ] 2>/dev/null; then
  _boot_hash=$(tr -cd '0-9a-fA-F' < "$BOOT_HASH_FILE" 2>/dev/null)
  log "BOOT_HASH" "Using existing hash file"
elif [ -b "$_vbmeta" ] 2>/dev/null; then
  _vbsize=$(blockdev --getsize64 "$_vbmeta" 2>/dev/null || echo "4096")
  _vbhash=$(sha256sum "$_vbmeta" 2>/dev/null | awk '{print $1}')

  resetprop -n ro.boot.vbmeta.size "$_vbsize" 2>/dev/null
  resetprop -n ro.boot.vbmeta.hash_alg "sha256" 2>/dev/null
  resetprop -n ro.boot.vbmeta.avb_version "2.0" 2>/dev/null

  if [ -n "$_vbhash" ]; then
    _boot_hash="$_vbhash"
    log "BOOT_HASH" "Read from block device: $_vbhash"
  fi
fi

if [ -z "$_boot_hash" ] || [ "${#_boot_hash}" -ne 64 ]; then
  _boot_hash="0000000000000000000000000000000000000000000000000000000000000000"
  log "BOOT_HASH" "Warning: No valid hash, using default (all zeros)"
fi

ensure_dir "$(dirname "$BOOT_HASH_FILE")"
echo "$_boot_hash" > "$BOOT_HASH_FILE" || die "Failed to write $BOOT_HASH_FILE"
chmod 644 "$BOOT_HASH_FILE" 2>/dev/null

resetprop -n ro.boot.vbmeta.digest "$_boot_hash" 2>/dev/null
log "BOOT_HASH" "Set vbmeta.digest = $_boot_hash"

unset _slot _vbmeta _boot_hash _vbsize _vbhash
log "BOOT_HASH" "Finish"
exit 0
