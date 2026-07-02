#!/system/bin/sh
set -e
MODDIR=${0%/*}
. "$MODDIR/../lib/common.sh"
. "$MODDIR/../lib/constants.sh"

detect_keystore_manager

case "${1:-}" in
  --fetch)
    _sp=$(download "https://source.android.com/docs/security/bulletin/pixel" 2>/dev/null |
      sed -n 's/.*<td>\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\)<\/td>.*/\1/p' |
      head -n 1)
    if [ -n "$_sp" ]; then
      echo "$_sp"
      exit 0
    fi
    exit 1
    ;;
  --get)
    [ -f "$KSM_SECURITY" ] || exit 1
    case "$KSM_FORMAT" in
      toml) grep -E '^[ ]*security_patch[ ]*=' "$KSM_SECURITY" 2>/dev/null | head -1 | sed 's/.*=[ ]*"\([^"]*\)".*/\1/' ;;
      *) grep -E '^(boot|all)=' "$KSM_SECURITY" 2>/dev/null | head -1 | cut -d= -f2 ;;
    esac
    exit 0
    ;;
  --set)
    case "${2:-}" in
      [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
      *) die "security_patch.sh --set requires a YYYY-MM-DD date" ;;
    esac
    ksm_available || die "No keystore manager (Tricky Store / OhMyKeymint) data directory found"
    ksm_set_security_patch "$2" || die "Failed to write $KSM_SECURITY"
    log_i "SECURITY_PATCH" "Security patch manually set to $2"
    exit 0
    ;;
esac

ksm_available || die "No keystore manager (Tricky Store / OhMyKeymint) data directory found"

# Try to fetch the real security patch date from source.android.com first.
# Network may not be available yet at boot, so fall back to date computation.
_patch=$(sh "$0" --fetch 2>/dev/null) || true

if [ -z "$_patch" ]; then
  current_year=$(date +%Y 2>/dev/null) || current_year=$(getprop ro.build.version.release 2>/dev/null | cut -d. -f1) || current_year="2026"
  current_month=$(date +%m 2>/dev/null) || current_month="01"

  patch_date="${current_year}-${current_month}-05"
  log_w "SECURITY_PATCH" "Network unavailable, using computed date: $patch_date"
else
  patch_date="$_patch"
  log_i "SECURITY_PATCH" "Fetched security patch date: $patch_date"
fi
unset _patch

ksm_set_security_patch "$patch_date" || die "Failed to write $KSM_SECURITY"
log_i "SECURITY_PATCH" "The security patch is written"
exit 0
