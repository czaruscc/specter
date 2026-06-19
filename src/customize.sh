# shellcheck shell=sh
# shellcheck disable=SC2034
MODDIR="$MODPATH"
. "$MODPATH/lib/common.sh"
. "$MODPATH/lib/config_env.sh"
. "$MODPATH/lib/urls.sh"

# Clean up old uppercase paths (module id + data dir)
rm -rf /data/adb/modules/Specter /data/adb/Specter

ui_print ""
ui_print "____                  _            "
ui_print "/ ___| _ __   ___  ___| |_ ___ _ __ "
ui_print "\\___ \\| '_ \\ / _ \\/ __| __/ _ \\ '__|"
ui_print " ___) | |_) |  __/ (__| ||  __/ |   "
ui_print "|____/| .__/ \\___|\\___|\\__\\___|_|   "
ui_print "      |_|                           "
ui_print ""

ui_print "- Checking device info..."
detect_root_solution
[ "$ROOT_TYPE" != "Unknown" ] && ui_print "- $ROOT_TYPE detected"

_ts_found=false
_ts_name=$(_ts_prop)
case "$_ts_name" in
  TEESimulator-RS) _ts_found=true; ui_print "- TEESimulator-RS found" ;;
  TEESimulator)    _ts_found=true; ui_print "- TEESimulator found" ;;
  *Tricky*)        _ts_found=true; ui_print "- Tricky Store found" ;;
  "")              ;;
  *)               _ts_found=true; ui_print "- $_ts_name found" ;;
esac
unset _ts_name

_pif_name=$(_pif_prop)
[ -n "$_pif_name" ] && ui_print "- $_pif_name found"
unset _pif_name

# TEE status check, read from cache only
_tee=
if [ -f "$TEE_STATUS" ]; then
  _tee_val=$(grep -E '^(teeBroken|tee_broken)=' "$TEE_STATUS" 2>/dev/null | cut -d= -f2)
  case "$_tee_val" in
    true)  _tee="broken" ;;
    false) _tee="normal" ;;
  esac
  unset _tee_val
fi
case "$_tee" in
  normal|broken)
    ui_print "- TEE: $_tee"
    ;;
esac
unset _tee

if [ "$_ts_found" = true ]; then
  ui_print ""
  ui_print " >> First-boot setup: backup, target, security patch, keybox, PIF (next reboot)"
else
  ui_print ""
  ui_print "- Tricky Store not found, checking for TEESimulator-RS..."
  check_network 2>/dev/null || { ui_print "- No network, skipping download"; true; }
  _gh_json=$(download "https://api.github.com/repos/Enginex0/TEESimulator-RS/releases/latest" "" 2>/dev/null) || _gh_json=""
  _dl_url=$(echo "$_gh_json" | grep '"browser_download_url":' | sed 's/.*"browser_download_url": *"\([^"]*\)".*/\1/')
  if [ -n "$_dl_url" ]; then
    _ts_zip="$MODPATH/teesimulator-rs.zip"
    case "$_dl_url" in
      *Debug*) ui_print "- Latest release is Debug-only, skipping" ;;
      *)
        ui_print "- Downloading TEESimulator-RS..."
        download "$_dl_url" "$_ts_zip" 2>/dev/null && {
          ui_print "- Installing TEESimulator-RS..."
          _ts_ok=1
          case "$ROOT_SOL" in
            magisk)  magisk --install-module "$_ts_zip" >/dev/null 2>&1 && _ts_ok=0 ;;
            kernelsu) ksud module install "$_ts_zip" >/dev/null 2>&1 && _ts_ok=0 ;;
            apatch)  apd module install "$_ts_zip" >/dev/null 2>&1 && _ts_ok=0 ;;
            *)       ui_print "- Unknown root ($ROOT_SOL), zip saved to $_ts_zip"; _ts_ok=0 ;;
          esac
          [ "$_ts_ok" = 0 ] && ui_print "- TEESimulator-RS installed" || ui_print "- Install failed"
          unset _ts_ok
        } || ui_print "- Download failed"
        rm -f "$_ts_zip"
        ;;
    esac
  else
    ui_print "- Could not fetch TEESimulator-RS release info"
  fi
  unset _gh_json _dl_url _ts_zip
fi
unset _ts_found

# Mark first-boot setup as pending (runs once after reboot in service.sh)
touch "$MODPATH/.first_boot_pending"

mkdir -p "$MODPATH/webroot/json"
echo "{\"MODDIR\": \"$MODPATH\", \"SPECTER_DIR\": \"$SPECTER_DIR\"}" > "$MODPATH/webroot/json/module_paths.json"

# Backup module.prop for description override system
cp "$MODPATH/module.prop" "$MODPATH/module.prop.bak"

# Mark TEE for first-boot check (removed by service.sh after running)
mkdir -p "$SPECTER_DIR"
echo "1" > "$SPECTER_DIR/tee_reported"
echo "1" > "$SPECTER_DIR/rom_spoof_reported"

# Ensure backup dir exists for first-boot snapshot
mkdir -p "$SPECTER_DIR/backup"

# Copy shipped config files to data dir
mkdir -p "$SPECTER_DIR/config"
cp "$MODPATH/config/conflicts.txt" "$SPECTER_DIR/config/conflicts.txt" 2>/dev/null || true

return 0
