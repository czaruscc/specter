#!/system/bin/sh
set -e
MODDIR=${0%/*}
[ -z "$KSU" ] && exit 0

. "$MODDIR/lib/common.sh"
. "$MODDIR/lib/package_list.sh"
. "$MODDIR/lib/config_env.sh"
export ROOT_SOL

log "BOOT" "KSU/APatch detected, sourcing unified boot core"

. "$MODDIR/lib/boot_core.sh"
