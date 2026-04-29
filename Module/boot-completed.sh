MODDIR=${0%/*}
# Guard: KernelSU and APatch both set $KSU=true; skip if not running under them
[ -z "$KSU" ] && exit 0

. "$MODDIR/lib/common.sh"
. "$MODDIR/lib/paths.sh"
. "$MODDIR/lib/config_env.sh"

settings put global development_settings_enabled 0
settings put global adb_enabled 0
settings put global oem_unlock_allowed 0
resetprop --delete persist.service.adb.enable
resetprop --delete persist.service.debuggable
resetprop -n persist.sys.developer_options 0

_release=$(getprop ro.build.version.release 2>/dev/null || echo "Unknown")
if [ -f "$TRICKY_DIR/keybox.xml" ]; then
    cfg_set "override.description" "Active | $_release"
else
    cfg_set "override.description" "Run action button to set up keybox"
fi
unset _release
