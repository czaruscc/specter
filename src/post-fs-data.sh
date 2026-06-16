#!/system/bin/sh
set -e
MODDIR=${0%/*}

. "$MODDIR/lib/common.sh"
. "$MODDIR/lib/config_env.sh"

detect_root_solution
export ROOT_SOL
resolve_conflicts

# APatch/KSU fallback: launch boot_core.sh asynchronously.
# service.sh defers to boot-completed.sh on KSU/APatch, but some
# module managers never trigger boot-completed.sh at all.
( sleep 15; . "$MODDIR/lib/boot_core.sh" ) &
