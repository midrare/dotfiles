#!/bin/sh

TMPFILE="/tmp/80-hidraw-access.rules"
DESTFILE="/etc/udev/rules.d/80-hidraw-access.rules"

CONTENT="# for HID-Remapper web UI through chrome
KERNEL==\"hidraw\", SUBSYSTEM==\"hidraw\", MODE=\"0660\", TAG+=\"access\""

if [[ -e "$DESTFILE" ]]; then
    desthash="$(md5sum "$DESTFILE" | cut -f1 -d " ")"
    srchash="$(printf "$CONTENT" | md5sum | cut -f1 -d " ")"

    if [[ "$desthash" == "$srchash" ]]; then
        exit 0
    fi
fi

echo "Updating $DESTFILE"
printf "$CONTENT" > "$TMPFILE"
chmod 644 "$TMPFILE"
sudo mv -f "$TMPFILE" "$DESTFILE"

