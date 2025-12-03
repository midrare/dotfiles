#!/bin/sh

TMPFILE="/tmp/lock-before-suspend"
DESTFILE="/usr/lib/systemd/system-sleep/lock-before-suspend"

CONTENT="#!/bin/sh
case \"\$1\" in
    # lock screen whenever computer sleeps (suspend)
    pre) loginctl lock-session;;
esac"

if [[ -e "$DESTFILE" ]]; then
    desthash="$(md5sum "$DESTFILE" | cut -f1 -d " ")"
    srchash="$(printf "$CONTENT" | md5sum | cut -f1 -d " ")"

    if [[ "$desthash" == "$srchash" ]]; then
        exit 0
    fi
fi

echo "Updating $DESTFILE"
printf "$CONTENT" > "$TMPFILE"
chmod 755 "$TMPFILE"
sudo mv -f "$TMPFILE" "$DESTFILE"

