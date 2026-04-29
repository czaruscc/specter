#!/system/bin/sh
MODDIR=${0%/*}
. "$MODDIR/../lib/common.sh"

log "PIF" "Start"

PIF_DIR="/data/adb/modules/playintegrityfix"

if [ ! -d "$PIF_DIR" ]; then
  log "PIF" "Warning: Play Integrity Fix not installed, skipping"
  exit 0
fi

MODULE_NAME=$(grep "^name=" "$PIF_DIR/module.prop" 2>/dev/null | cut -d= -f2-)
[ -z "$MODULE_NAME" ] && { log "PIF" "Warning: Cannot read module.prop, skipping"; exit 0; }

case "$MODULE_NAME" in
  "Play Integrity Fix [INJECT]")
    log "PIF" "Detected INJECT variant"
    sh "$PIF_DIR/autopif_ota.sh" 2>/dev/null || true
    sh "$PIF_DIR/autopif.sh" 2>/dev/null || log "PIF" "Warning: autopif.sh failed"
    ;;
  "Play Integrity Fork")
    log "PIF" "Detected Fork variant"
    sh "$PIF_DIR/autopif4.sh" -m 2>/dev/null || log "PIF" "Warning: autopif4.sh failed"
    ;;
  *)
    log "PIF" "Warning: Unknown module: $MODULE_NAME"
    exit 0
    ;;
esac

log "PIF" "Finish"
exit 0
