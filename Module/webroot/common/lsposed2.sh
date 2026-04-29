#!/system/bin/sh
MODDIR=${0%/*}
. "$MODDIR/../../lib/common.sh"

log "LSPOSED2" "Start"
_count=$(find /data/app -type f -name base.odex 2>/dev/null | wc -l)
find /data/app -type f -name base.odex -delete 2>/dev/null
log "LSPOSED2" "Deleted $_count base.odex files"
log "LSPOSED2" "Finish"