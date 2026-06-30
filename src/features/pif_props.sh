#!/system/bin/sh
set -e
MODDIR=${0%/*}
. "$MODDIR/../lib/common.sh"
. "$MODDIR/../lib/constants.sh"

[ "$(cfg_get toggle_pif_props 1)" = "0" ] && exit 0

# Check if BRENE handles PIF props cleanup
if [ -d "/data/adb/modules/brene" ] && [ -f "/data/adb/brene/config.sh" ]; then
  _brene_pif=$(grep '^config_pif_props=' /data/adb/brene/config.sh 2>/dev/null | cut -d= -f2)
  [ "$_brene_pif" = "1" ] && { log_d "PIXEL_PROPS" "BRENE handles PIF props, skipping"; unset _brene_pif; exit 0; }
  unset _brene_pif
fi

log_i "PIXEL_PROPS" "Cleaning PIHook/PixelProps/spoof props"

_cleaned=0
_props=$(resetprop 2>/dev/null | grep -iE 'pihook|pixelprops|spoof|entryhooks' | cut -d'[' -f2 | cut -d']' -f1 || true)
for _prop in $_props; do
  [ -z "$_prop" ] && continue
  resetprop --delete "$_prop" 2>/dev/null || true
  _cleaned=$((_cleaned + 1))
done
unset _prop _props

# Also handle GMS certified props file
if [ -f "$GMS_PROPS_FILE" ] && [ "$(resetprop persist.sys.spoof.gms 2>/dev/null)" != "false" ]; then
  resetprop persist.sys.spoof.gms false 2>/dev/null || true
  log_i "PIXEL_PROPS" "persist.sys.spoof.gms → false"
  _cleaned=$((_cleaned + 1))
fi

if [ "$_cleaned" -gt 0 ]; then
  log_i "PIXEL_PROPS" "Cleaned $_cleaned spoof props"
else
  log_i "PIXEL_PROPS" "No spoof props found"
fi
unset _cleaned
