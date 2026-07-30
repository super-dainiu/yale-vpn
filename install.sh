#!/usr/bin/env bash
set -Eeuo pipefail

[[ ${EUID} -eq 0 ]] || {
  echo "Run with sudo: sudo bash install.sh" >&2
  exit 2
}

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

apt-get update
apt-get install -y curl nftables openconnect
install -m 0755 "$root/yale-vpn" /usr/local/sbin/yale-vpn
ln -sfn /usr/local/sbin/yale-vpn /usr/local/sbin/yale-open-url

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
Description=Check the cloud SSH route every 30 seconds

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
