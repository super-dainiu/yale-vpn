#!/usr/bin/env bash
set -Eeuo pipefail

[[ ${EUID} -eq 0 ]] || {
  echo "Run with sudo: sudo bash install.sh" >&2
  exit 2
}

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

apt-get update
apt-get install -y \
  ca-certificates \
  chromium-chromedriver \
  curl \
  nftables \
  openconnect \
  python3-selenium

if ! command -v google-chrome-stable >/dev/null; then
  [[ $(dpkg --print-architecture) == amd64 ]] || {
    echo "Headless login currently requires an amd64 Ubuntu host" >&2
    exit 1
  }
  chrome_deb=$(mktemp --suffix=.deb)
  trap 'rm -f "$chrome_deb"' EXIT
  curl -fsSL \
    https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    -o "$chrome_deb"
  apt-get install -y "$chrome_deb"
fi

# Chrome needs breathing room on a 512 MiB Lightsail instance.
if (( $(awk '/MemTotal/ {print $2}' /proc/meminfo) < 750000 )) &&
   ! swapon --show=NAME --noheadings | grep -qx /swapfile; then
  if [[ ! -f /swapfile ]]; then
    fallocate -l 1G /swapfile
    chmod 0600 /swapfile
    mkswap /swapfile
  fi
  swapon /swapfile
  grep -q '^/swapfile ' /etc/fstab ||
    printf '%s\n' '/swapfile none swap sw 0 0' >>/etc/fstab
fi

install -m 0755 "$root/yale-vpn" /usr/local/sbin/yale-vpn
install -m 0755 "$root/yale-sso-browser" /usr/local/sbin/yale-sso-browser
unlink /usr/local/sbin/yale-open-url 2>/dev/null || true

# networkd otherwise removes our policy rules during some package upgrades.
install -d -m 0755 /etc/systemd/networkd.conf.d
install -m 0644 /dev/stdin \
  /etc/systemd/networkd.conf.d/90-yale-management.conf <<'EOF'
[Network]
ManageForeignRoutes=no
ManageForeignRoutingPolicyRules=no
EOF

install -m 0644 /dev/stdin \
  /etc/systemd/system/yale-route.service <<'EOF'
[Unit]
Description=Keep cloud SSH outside the Yale VPN
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/yale-vpn route

[Install]
WantedBy=multi-user.target
EOF

install -m 0644 /dev/stdin \
  /etc/systemd/system/yale-route-watchdog.service <<'EOF'
[Unit]
Description=Repair the cloud SSH route after network changes

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/yale-vpn watchdog
EOF

install -m 0644 /dev/stdin \
  /etc/systemd/system/yale-route-watchdog.timer <<'EOF'
[Unit]
Description=Check the cloud SSH route every 5 seconds

[Timer]
OnBootSec=5s
OnUnitActiveSec=5s
AccuracySec=1s

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable --now yale-route.service yale-route-watchdog.timer

echo "Installed. Next: sudo yale-vpn connect"
