#!/system/bin/sh
MODDIR="${0%/*}"
MODDIR="${MODDIR%/*}"
MODDIR="${MODDIR%/*}"
. "$MODDIR/lib/common.sh"

INFO_PATH="$MODDIR/webroot/json/device-info.json"

_android_ver=$(getprop ro.build.version.release)
_kernel_ver=$(uname -r)

# Root Implementation
_root_type="Unknown"
if [ -d "/data/adb/magisk" ] && [ -f "/data/adb/magisk.db" ]; then
  _root_type="Magisk"
elif [ -f "/data/apatch/apatch" ]; then
  _root_type="Apatch"
elif [ -d "/data/adb/ksu" ] && { [ -d "/data/adb/kpm" ] || [ -f "/data/adb/ksu/.dynamic_sign" ]; }; then
  _root_type="SukiSU-Ultra"
elif [ -d "/data/adb/ksu" ] && { [ -f "/data/adb/ksud" ] || [ -f "/sys/module/kernelsu/parameters/expected_manager_size" ]; ]; then
  _root_type="KernelSU-Next"
elif [ -d "/data/adb/ksu" ]; then
  _root_type="KernelSU"
fi

# Output JSON
cat <<EOF > "$INFO_PATH"
{
  "android": "$_android_ver",
  "kernel": "$_kernel_ver",
  "root": "$_root_type"
}
EOF
unset _android_ver _kernel_ver _root_type