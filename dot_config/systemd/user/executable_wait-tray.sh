#!/bin/bash

while ! /bin/busctl --user status org.kde.StatusNotifierWatcher &>/dev/null; do
    /bin/sleep 0.1
done

/bin/sleep 0.1
