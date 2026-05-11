#!/system/bin/sh
set -e
MODDIR=${0%/*}
. "$MODDIR/../lib/common.sh"
. "$MODDIR/../lib/paths.sh"
. "$MODDIR/../lib/config_env.sh"

log "BOOT_HASH" "Start"

_boot_hash=""

# 1. Check existing system property — set by bootloader on locked devices
_boot_hash=$(getprop ro.boot.vbmeta.digest 2>/dev/null || echo "")
if [ -n "$_boot_hash" ] && [ "${#_boot_hash}" -eq 64 ]; then
  log "BOOT_HASH" "From system property: $_boot_hash"
fi

# 2. Check kernel cmdline — survives module interference
if [ -z "$_boot_hash" ]; then
  _boot_hash=$(grep -o 'androidboot\.vbmeta\.digest=[a-f0-9]\{64\}' /proc/cmdline 2>/dev/null | cut -d= -f2)
  if [ -n "$_boot_hash" ]; then
    log "BOOT_HASH" "From kernel cmdline: $_boot_hash"
  fi
fi

# 3. User-provided config file
if [ -z "$_boot_hash" ] && [ -f "/sdcard/Specter/boot_hash" ] 2>/dev/null; then
  _boot_hash=$(tr -cd '0-9a-fA-F' < "/sdcard/Specter/boot_hash" 2>/dev/null)
  if [ -n "$_boot_hash" ] && [ "${#_boot_hash}" -eq 64 ] && [ "$_boot_hash" != "0000000000000000000000000000000000000000000000000000000000000000" ]; then
    log "BOOT_HASH" "From user config: /sdcard/Specter/boot_hash"
  else
    _boot_hash=""
  fi
fi

# 4. Stored hash from previous boot
if [ -z "$_boot_hash" ] && [ -f "$BOOT_HASH_FILE" ] 2>/dev/null; then
  _boot_hash=$(tr -cd '0-9a-fA-F' < "$BOOT_HASH_FILE" 2>/dev/null)
  if [ -n "$_boot_hash" ] && [ "${#_boot_hash}" -eq 64 ] && [ "$_boot_hash" != "0000000000000000000000000000000000000000000000000000000000000000" ]; then
    log "BOOT_HASH" "From stored file: $BOOT_HASH_FILE"
  else
    _boot_hash=""
  fi
fi

# 5. If still no valid hash, skip entirely — no zeros, no prop pollution
if [ -z "$_boot_hash" ] || [ "${#_boot_hash}" -ne 64 ]; then
  log "BOOT_HASH" "No valid boot hash available — skipping"
  exit 0
fi

ensure_dir "$(dirname "$BOOT_HASH_FILE")"
echo "$_boot_hash" > "$BOOT_HASH_FILE" || die "Write failed: $BOOT_HASH_FILE"
chmod 644 "$BOOT_HASH_FILE" 2>/dev/null || true
cfg_set "stored_boot_hash" "$_boot_hash"

resetprop -n ro.boot.vbmeta.digest "$_boot_hash" 2>/dev/null || log "BOOT_HASH" "Failed to set vbmeta.digest"
resetprop -n ro.boot.vbmeta.hash_alg "sha256" 2>/dev/null || true
resetprop -n ro.boot.vbmeta.avb_version "2.0" 2>/dev/null || true
resetprop -n ro.boot.vbmeta.invalidate_on_error "yes" 2>/dev/null || true

# Compute vbmeta size from AVB header (not raw partition size)
_vbmeta_size=""
for _vbdev in \
  "/dev/block/by-name/vbmeta$(getprop ro.boot.slot_suffix 2>/dev/null)" \
  "/dev/block/by-name/vbmeta" \
  "/dev/block/by-name/vbmeta_a" \
  "/dev/block/by-name/vbmeta_b"; do
  [ -b "$_vbdev" ] || continue
  _avb_magic=$(dd if="$_vbdev" bs=1 count=4 2>/dev/null)
  [ "$_avb_magic" = "AVB0" ] || continue
  _auth_hex=$(dd if="$_vbdev" bs=1 skip=12 count=8 2>/dev/null | od -A n -t x1 | tr -d ' \n' | sed 's/^0*//')
  _aux_hex=$(dd if="$_vbdev" bs=1 skip=20 count=8 2>/dev/null | od -A n -t x1 | tr -d ' \n' | sed 's/^0*//')
  _vbmeta_size=$((256 + 0x${_auth_hex:-0} + 0x${_aux_hex:-0}))
  [ "$_vbmeta_size" -gt 256 ] 2>/dev/null && break
  _vbmeta_size=""
done
resetprop -n ro.boot.vbmeta.size "${_vbmeta_size:-4096}" 2>/dev/null || true
unset _vbdev _avb_magic _auth_hex _aux_hex _vbmeta_size

log "BOOT_HASH" "vbmeta.digest = $_boot_hash"

unset _boot_hash
log "BOOT_HASH" "Finish"
exit 0
