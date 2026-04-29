#!/system/bin/sh
MODDIR=${0%/*}
. "$MODDIR/../lib/common.sh"
. "$MODDIR/../lib/paths.sh"
. "$MODDIR/../lib/urls.sh"

log "WIDEVINE" "Start"

TMPDIR="/data/local/tmp"
FW_SCRIPT="$MODDIR/../webroot/common/FixWidevineL1/FixWidevineL1.sh"

# Download attestation key at runtime (not bundled — like keybox)
log "WIDEVINE" "Downloading attestation key..."
download "$ATTESTATION_URL" > "$TMPDIR/attestation" 2>/dev/null || {
  log "WIDEVINE" "Error: Failed to download attestation key"
  exit 1
}

# Copy the FixWidevineL1.sh script from module
if [ -f "$FW_SCRIPT" ]; then
  cp "$FW_SCRIPT" "$TMPDIR/FixWidevineL1.sh" 2>/dev/null || {
    log "WIDEVINE" "Error: Failed to copy FixWidevineL1.sh"
    rm -f "$TMPDIR/attestation"
    exit 1
  }
else
  log "WIDEVINE" "Error: FixWidevineL1.sh not found at $FW_SCRIPT"
  rm -f "$TMPDIR/attestation"
  exit 1
fi

chmod 755 "$TMPDIR/FixWidevineL1.sh" 2>/dev/null
chmod 755 "$TMPDIR/attestation" 2>/dev/null
chown root:root "$TMPDIR/FixWidevineL1.sh" 2>/dev/null
chown root:root "$TMPDIR/attestation" 2>/dev/null

_abi=$(getprop ro.product.cpu.abi 2>/dev/null)
case "$_abi" in
  arm64|x86_64) _lib="/vendor/lib64/hw" ;;
  *)            _lib="/vendor/lib/hw" ;;
esac

KM_BIN=""
[ -f /vendor/bin/KmInstallKeybox ]    && KM_BIN=/vendor/bin/KmInstallKeybox
[ -f /system/bin/KmInstallKeybox ]    && KM_BIN=/system/bin/KmInstallKeybox
[ -f /vendor/bin/hw/KmInstallKeybox ] && KM_BIN=/vendor/bin/hw/KmInstallKeybox

if [ -n "$KM_BIN" ]; then
  LD_LIBRARY_PATH="$_lib" "$KM_BIN" "$TMPDIR/attestation" 2>/dev/null || \
    log "WIDEVINE" "Warning: KmInstallKeybox exited non-zero"
else
  log "WIDEVINE" "Warning: KmInstallKeybox not found (non-Qualcomm device?)"
fi
unset KM_BIN
unset _abi _lib

rm -f "$TMPDIR/FixWidevineL1.sh" "$TMPDIR/attestation" 2>/dev/null

log "WIDEVINE" "Finish"
exit 0
