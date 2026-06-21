#!/bin/bash
# Build and push module directly to device
# Usage: ./scripts/push.sh

ZIP=$(ls /home/dpejoh/code/specter/module/Specter-*.zip 2>/dev/null | sort | tail -1)
if [ -z "$ZIP" ]; then
  echo "No zip found. Run 'npm run build' first."
  exit 1
fi

echo "Pushing: $ZIP"
adb push "$ZIP" /sdcard/specter-update/ || exit 1

echo "Deploying..."
adb shell su -c sh /sdcard/specter-update/deploy-module.sh /sdcard/specter-update/$(basename "$ZIP")
echo "Done. Hard-refresh the webui page."
