#!/system/bin/sh
MODULE_ROOT="${0%/*}"
MODULE_ROOT="${MODULE_ROOT%/webroot/common}"
. "$MODULE_ROOT/lib/common.sh"
sh "$MODULE_ROOT/features/pif2.sh"
