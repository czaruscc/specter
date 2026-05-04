#!/system/bin/sh
MODDIR=${0%/*}
. "$MODDIR/../lib/common.sh"
. "$MODDIR/../lib/paths.sh"
. "$MODDIR/../lib/urls.sh"
trap 'rm -f /data/local/tmp/attestation 2>/dev/null' EXIT

log "WIDEVINE" "Start"

check_network || { log "WIDEVINE" "Error: No internet connection"; exit 1; }

WDIR="/data/local/tmp"

log "WIDEVINE" "Downloading attestation key..."
download "$ATTESTATION_URL" > "$WDIR/attestation" 2>/dev/null || {
  log "WIDEVINE" "Error: Failed to download attestation key"
  exit 1
}
log "WIDEVINE" "Attestation key downloaded successfully"

chmod 755 "$WDIR/attestation" 2>/dev/null || log "WIDEVINE" "Warning: Failed to set permissions on attestation"
chown root:root "$WDIR/attestation" 2>/dev/null || log "WIDEVINE" "Warning: Failed to set owner on attestation"

_abi=$(getprop ro.product.cpu.abi 2>/dev/null)
case "$_abi" in
  arm64|x86_64) _lib="/vendor/lib64/hw" ;;
  *)            _lib="/vendor/lib/hw" ;;
esac

log "WIDEVINE" "Searching for KmInstallKeybox vendor binary..."
KM_BIN=$(find_kmInstallKeybox)

if [ -n "$KM_BIN" ]; then
  log "WIDEVINE" "Found KmInstallKeybox at $KM_BIN"
  log "WIDEVINE" "Running KmInstallKeybox with attestation key..."
  LD_LIBRARY_PATH="$_lib" "$KM_BIN" "$WDIR/attestation" attestation true 2>/dev/null || {
    log "WIDEVINE" "Error: KmInstallKeybox exited with non-zero status"
    rm -f "$WDIR/attestation"
    exit 1
  }
  log "WIDEVINE" "KmInstallKeybox completed successfully"
else
  log "WIDEVINE" "Error: KmInstallKeybox not found (non-Qualcomm device?)"
  rm -f "$WDIR/attestation"
  exit 1
fi
unset KM_BIN
unset _abi _lib

rm -f "$WDIR/attestation" 2>/dev/null

log "WIDEVINE" "Finish"
exit 0
