#!/bin/sh
# iMac Sierra installer rescue, 2026-10-28.
# Inspect at: https://github.com/Ricardot14/ricardot14-github.io/blob/master/r
# This script only changes /Volumes/Macintosh HD/InstallOS.dmg if its size
# is exactly 5007882938 bytes (812 bytes too long).
set -u
F="/Volumes/Macintosh HD/InstallOS.dmg"
GOOD=5007882126
BAD=5007882938

echo "=== iMac Sierra installer rescue ==="
echo "This will NOT erase a disk or download another installer."
if [ ! -f "$F" ]; then
  echo "STOP: installer not found at $F"
  exit 1
fi
SIZE=$(/usr/bin/stat -f%z "$F") || exit 1
echo "Existing image size: $SIZE bytes"
if [ "$SIZE" = "$BAD" ]; then
  echo "812 extra bytes detected after the expected 5007882126-byte image."
  printf "Trim exactly those 812 trailing bytes? [y/N] "
  read REPLY </dev/tty || exit 1
  case "$REPLY" in
    y|Y) ;;
    *) echo "Cancelled without changes."; exit 0 ;;
  esac
  /bin/dd if=/dev/null of="$F" bs=1 seek="$GOOD" count=0 || {
    echo "STOP: could not trim image."
    exit 1
  }
elif [ "$SIZE" = "$GOOD" ]; then
  echo "Image is already at the expected length."
else
  echo "STOP: unexpected image size; nothing was modified."
  exit 1
fi

NEW_SIZE=$(/usr/bin/stat -f%z "$F") || exit 1
if [ "$NEW_SIZE" != "$GOOD" ]; then
  echo "STOP: resulting image size is unexpected: $NEW_SIZE"
  exit 1
fi
echo "Trying to mount the image read-only..."
if ! /usr/bin/hdiutil attach -readonly "$F"; then
  echo "STOP: image could not be mounted. Do not try to install from it."
  exit 1
fi
echo "Image mounted successfully."
PKG="/Volumes/Install macOS/InstallOS.pkg"
if [ ! -f "$PKG" ]; then
  echo "Could not locate $PKG; inspect the mounted volume before proceeding."
  exit 0
fi
printf "Extract the Sierra installer onto Macintosh HD and launch it? [y/N] "
read REPLY </dev/tty || exit 1
case "$REPLY" in
  y|Y) ;;
  *) echo "Stopped after mounting; nothing else changed."; exit 0 ;;
esac
/usr/sbin/installer -pkg "$PKG" -target "/Volumes/Macintosh HD" || {
  echo "Package installation failed. Do not proceed."
  exit 1
}
APP="/Volumes/Macintosh HD/Applications/Install macOS Sierra.app/Contents/MacOS/Installassistant_springboard"
if [ ! -x "$APP" ]; then
  echo "Installer application missing from expected location: $APP"
  exit 1
fi
echo "Launching the macOS Sierra installer. Keep Terminal open."
"$APP"
