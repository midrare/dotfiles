#!/bin/sh

TMPFILE="/tmp/i915.conf"
DESTFILE="/etc/modprobe.d/i915.conf"
CONTENT="options i915 enable_psr=0"


if [ -f "$DESTFILE" ]; then
    desthash="$(md5sum "$DESTFILE" | cut -f1 -d " ")"
    srchash="$(printf "$CONTENT" | md5sum | cut -f1 -d " ")"

    if [ "$desthash" = "$srchash" ]; then
        exit 0
    fi
fi

echo "Updating $DESTFILE"
printf "$CONTENT" > "$TMPFILE"
chmod 644 "$TMPFILE"
sudo mv -f "$TMPFILE" "$DESTFILE"

