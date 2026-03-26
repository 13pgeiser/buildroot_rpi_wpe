#!/bin/sh
SERVER="192.168.0.222"
URL="http://${SERVER}:3000/d/574d7f7f-bc36-4dce-abf0-c2ddb74a452b/power?orgId=1&from=now-30m&to=now&timezone=browser&refresh=5s&kiosk=1"
echo "waiting for network"
while ! ping -c 1 -n -w 1 $SERVER >/dev/null; do
    printf "%c" "."
done
echo "network ready"
if pidof "PaGBrowser" > /dev/null; then
    echo "PaGBrowser Running"
else
    export XDG_RUNTIME_DIR=/tmp/weston
    mkdir -p $XDG_RUNTIME_DIR
    chmod 700 $XDG_RUNTIME_DIR
    weston --log /tmp/weston.txt &
    sleep 1
    export WAYLAND_DISPLAY=wayland-1
    /usr/bin/PaGBrowser &
fi
