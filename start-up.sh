#!/bin/bash

set -eu

if [ -d /shared ]; then
	sed -i 's|^#custom_services_dir = .*|custom_services_dir = /shared/|' /opt/core/etc/core.conf
fi

mkdir -p /var/run/sshd /tmp/.X11-unix

if [ "${ENABLE_SSH:-0}" = "1" ]; then
	service ssh start
fi

Xvfb "$DISPLAY" -screen 0 1920x1080x24 &
openbox &
x11vnc -display "$DISPLAY" -forever -shared -rfbport 5900 -nopw &
/usr/share/novnc/utils/launch.sh --vnc localhost:5900 --listen 6080 --web /usr/share/novnc &

core-daemon &
daemon_pid=$!
sleep 3

core-gui >/var/log/core-gui.log 2>&1 || true &

wait "$daemon_pid"
