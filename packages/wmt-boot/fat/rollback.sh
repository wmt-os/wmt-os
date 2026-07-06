#!/bin/sh
set -e
CDPATH='' cd -- "$(dirname -- "$0")"

echo "WMT OS Kernel Rollback"
echo

if [ ! -f script/version ]; then
	echo "Cannot find the script folder. Run this from the card's root."
	exit 1
fi
if [ ! -f script.bak/version ]; then
	echo "Only one kernel is installed. Nothing to roll back to."
	exit 1
fi

echo "Current version:"
cat script/version
echo "Previous version:"
cat script.bak/version
printf 'Press Enter to switch, or Ctrl-C to cancel. '
read -r _

rm -rf script.tmp
mv script script.tmp
mv script.bak script
mv script.tmp script.bak
sync

echo "Done. The device will next boot:"
cat script/version
echo "You may now reboot. Run this again to switch back."
