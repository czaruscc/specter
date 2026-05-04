#!/system/bin/sh
MODDIR=${0%/*}
. "$MODDIR/../lib/common.sh"

log "GMS" "Start"

_installed_pkgs=$(pm list packages 2>/dev/null)
_count=0

for _pkg in com.android.vending com.android.chrome com.google.android.googlequicksearchbox com.google.android.ims com.google.android.gms com.google.android.gms.persistent com.google.android.gms.unstable com.google.android.gsf com.google.android.contactkeys com.google.android.rkpdapp com.google.android.widevine com.google.android.apps.bard com.google.android.apps.walletnfcrel com.google.android.apps.messaging; do
  echo "$_installed_pkgs" | grep -Fq "package:$_pkg" || continue
  log "GMS" "Force-stopping $_pkg"
  am force-stop "$_pkg" >/dev/null 2>&1 || log "GMS" "Warning: Failed to force-stop $_pkg"
  _count=$((_count + 1))
done

if echo "$_installed_pkgs" | grep -q "package:com.android.vending"; then
  log "GMS" "Trimming Play Store cache..."
  cmd package trim-caches 999999999 com.android.vending >/dev/null 2>&1 || log "GMS" "Warning: Failed to clear Play Store cache"
fi
unset _installed_pkgs

log "GMS" "Force-stopped $_count packages"
log "GMS" "Finish"
exit 0
