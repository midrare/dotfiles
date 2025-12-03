#!/bin/sh

TMPFILE="/tmp/monitor-suspend.service"
DESTFILE="/etc/systemd/system/monitor-suspend.service"

CONTENT="# Fixes bug where DisplayPort monitors repeatedly reconnect after
# waking computer from sleep (suspend)

[Unit]
Description=Reprobe monitors after suspend
After=suspend.target

[Service]
Type=oneshot
ExecStart=-/usr/bin/xrandr --auto
ExecStart=-/usr/bin/hyprctl reload
Restart=on-failure
RestartSec=0.75
StartLimitInterval=10
StartLimitBurst=6

[Install]
WantedBy=suspend.target"

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

sudo systemctl enable monitor-suspend.service
sudo systemctl start monitor-suspend.service

