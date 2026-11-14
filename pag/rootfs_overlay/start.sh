#!/bin/sh
# PaGBrowser kiosk launcher.
#
# Invoked by init.d/S99PagBrowser once at boot (and, defensively, by cron).
# Its job: diagnose the network, then bring up Weston + PaGBrowser.
#
# The network wait below is BOUNDED: if the Grafana server at $SERVER is not
# reachable within MAX_WAIT seconds we print a warning and launch anyway, so a
# missing/down network can never hang the kiosk forever.

SERVER="192.168.0.222"
URL="http://${SERVER}:3000/d/574d7f7f-bc36-4dce-abf0-c2ddb74a452b/power?orgId=1&from=now-30m&to=now&timezone=browser&refresh=5s&kiosk=1"

# How long (seconds) to wait for the server before launching anyway.
MAX_WAIT=60
# Delay between ping attempts while waiting (seconds).
PING_INTERVAL=3

# Everything is echoed to the console (tty1) AND saved to a log, so we can
# inspect what happened after the fact.
LOG=/tmp/start.log

# --- Idempotency: only ever run the full sequence once. ----------------------
# Cron may call us repeatedly; if the browser is already up there is nothing to
# do, so exit immediately (this keeps cron a cheap no-op when healthy).
if pidof PaGBrowser >/dev/null 2>&1; then
	exit 0
fi

: > "$LOG"
: >> "$LOG"

banner() {
	echo
	echo "============================================================"
	echo "$1"
	echo "============================================================"
}

# Print to console and append to the log.
log() {
	echo "$@" | tee -a "$LOG"
}

dmesg_tail() {
	if command -v dmesg >/dev/null 2>&1; then
		dmesg 2>/dev/null | tail -n 40
	else
		cat /var/log/dmesg 2>/dev/null
	fi
}

network_debug() {
	log "---- interfaces ----"
	if command -v ip >/dev/null 2>&1; then
		ip -o addr 2>/dev/null || ip addr 2>/dev/null
	else
		ifconfig -a 2>/dev/null || netstat -i 2>/dev/null
	fi
	log "---- routing ----"
	if command -v ip >/dev/null 2>&1; then
		ip route 2>/dev/null || ip route show 2>/dev/null
	else
		netstat -rn 2>/dev/null
	fi
	log "---- wifi ----"
	if command -v iwconfig >/dev/null 2>&1; then
		iwconfig 2>/dev/null || log "(iwconfig: no info)"
	else
		log "(iwconfig not available)"
	fi
	log "---- resolv.conf ----"
	if [ -r /etc/resolv.conf ]; then
		cat /etc/resolv.conf
	else
		log "(no /etc/resolv.conf)"
	fi
	log "---- wpa_supplicant ----"
	if pidof wpa_supplicant >/dev/null 2>&1; then
		log "running: $(pidof wpa_supplicant | tr ' ' ',')"
	else
		log "NOT running"
	fi
}

banner "PaGBrowser kiosk starting — $(date)"
log "kernel uptime: $(uptime 2>/dev/null)"
log "---- kernel log (tail) ----"
dmesg_tail
network_debug

# --- Bounded wait for the server to answer pings -----------------------------
log ""
log "waiting for server $SERVER (up to ${MAX_WAIT}s)..."
deadline=$(( $(date +%s) + MAX_WAIT ))
reachable=0
while : ; do
	if ping -c 1 -n -w 1 "$SERVER" >/dev/null 2>&1; then
		log "server $SERVER answered a ping."
		reachable=1
		break
	fi
	now=$(date +%s)
	if [ "$now" -ge "$deadline" ]; then
		log "!! server $SERVER did not answer within ${MAX_WAIT}s."
		log "    last-known network state:"
		network_debug
		log "!! continuing anyway — launching PaGBrowser without network confirmation."
		break
	fi
	printf "."
	sleep "$PING_INTERVAL"
done
echo
if [ "$reachable" -eq 1 ]; then
	log "network check OK."
else
	log "network check FAILED — proceeding without it."
fi

# --- Bring up Weston + PaGBrowser (never a second copy) ----------------------
if ! pidof weston >/dev/null 2>&1; then
	export XDG_RUNTIME_DIR=/tmp/weston
	mkdir -p "$XDG_RUNTIME_DIR"
	chmod 700 "$XDG_RUNTIME_DIR"
	log "launching weston ..."
	weston --log /tmp/weston.txt >/tmp/weston.stdout 2>&1 &
	sleep 2
else
	log "weston already running."
fi

# Light thermal headroom.
echo 4 >/sys/class/thermal/cooling_device0/cur_state 2>/dev/null || true

export WAYLAND_DISPLAY=wayland-1
log "launching PaGBrowser:"
log "    $URL"
/usr/bin/PaGBrowser &

banner "Launched. Full log: $LOG"
