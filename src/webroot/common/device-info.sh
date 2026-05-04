#!/system/bin/sh
. /data/adb/modules/Specter/lib/common.sh 2>/dev/null
MODULE_ROOT=$(resolve_module_root)

INFO_PATH="$MODULE_ROOT/webroot/json/info.json"

_android_ver=$(_escape_json "$(getprop ro.build.version.release)")
_kernel_ver=$(_escape_json "$(uname -r)")
_version=$(_escape_json "$(grep '^version=' "$MODULE_ROOT/module.prop" | cut -d'=' -f2)")

# Root Implementation
# Strategy: kernel-level root providers first, then userspace
# Most-specific variant checks before generic catch-alls
_root_type="Unknown"
if [ -d "/data/adb/ap" ]; then
  _root_type="APatch"
elif [ -d "/data/adb/ksu" ]; then
  if [ -f "/data/adb/ksu/.dynamic_sign" ]; then
    _root_type="SukiSU-Ultra"
  elif [ -f "/sys/module/kernelsu/parameters/expected_manager_size" ]; then
    _root_type="KernelSU-Next"
  else
    _root_type="KernelSU"
  fi
elif [ -d "/data/adb/magisk" ] && [ -f "/data/adb/magisk.db" ]; then
  _root_type="Magisk"
fi

# Root solution
. /data/adb/modules/Specter/lib/common.sh 2>/dev/null
detect_root_solution
ROOT_SOL=$ROOT_SOL

# Keybox format
if [ -f "/data/adb/tricky_store/locked.xml" ]; then
  _keybox_format="locked.xml"
elif [ -f "/data/adb/tricky_store/keybox.xml" ]; then
  _keybox_format="keybox.xml"
else
  _keybox_format="none"
fi

# Flags
_twrp="false"; [ -f "/data/adb/Specter/twrp" ] && _twrp="true"
_blacklist="false"; [ -f "/data/adb/Specter/blacklist_enabled" ] && _blacklist="true"
# Output JSON
cat <<EOF > "$INFO_PATH"
{
  "android": "$_android_ver",
  "kernel": "$_kernel_ver",
  "root": "$_root_type",
  "root_sol": "$ROOT_SOL",
  "version": "$_version",
  "keybox_format": "$_keybox_format",
  "flags": {
    "twrp": $_twrp,
    "blacklist": $_blacklist
  }
}
EOF
unset _android_ver _kernel_ver _root_type _version _keybox_format _twrp _blacklist

# Clean up ROOT_SOL variable
unset ROOT_SOL