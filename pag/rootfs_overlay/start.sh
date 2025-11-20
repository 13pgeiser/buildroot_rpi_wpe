
export XDG_RUNTIME_DIR=/tmp/weston
mkdir -p $XDG_RUNTIME_DIR
chmod 700 $XDG_RUNTIME_DIR
weston --log /log.txt &
sleep 1
export WAYLAND_DISPLAY=wayland-1
URL="https://www.google.ch"
cog -P wl "$URL" &
sleep 2
killall cog
export COG_PLATFORM_WL_VIEW_FULLSCREEN=1
cog -P wl "$URL"

