#!/usr/bin/env bash
set -Eeuo pipefail

if [[ ${EUID} -ne 0 ]]; then
  echo "Run with sudo: sudo bash install.sh" >&2
  exit 2
fi
if [[ $(dpkg --print-architecture) != amd64 ]]; then
  echo "This installer currently supports x86-64/amd64 only." >&2
  exit 2
fi

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y \
  ca-certificates \
  curl \
  jq \
  nftables \
  openconnect \
  python3-selenium \
  unzip

if ! command -v google-chrome-stable >/dev/null; then
  curl -fsSL \
    https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    -o "$tmp/google-chrome.deb"
  apt-get install -y "$tmp/google-chrome.deb"
fi

chrome_version=$(google-chrome-stable --version | awk '{print $3}')
chrome_build=${chrome_version%.*}
metadata_url=https://googlechromelabs.github.io/chrome-for-testing/latest-patch-versions-per-build-with-downloads.json
driver_url=$(
  curl -fsSL "$metadata_url" |
    jq -r --arg build "$chrome_build" \
      '.builds[$build].downloads.chromedriver[]? |
       select(.platform == "linux64") | .url' |
    head -n1
)
if [[ -z $driver_url || $driver_url == null ]]; then
  echo "No ChromeDriver found for Chrome build $chrome_build." >&2
  exit 1
fi

curl -fsSL "$driver_url" -o "$tmp/chromedriver.zip"
unzip -q "$tmp/chromedriver.zip" -d "$tmp/chromedriver"
install -d -o root -g root -m 0755 /usr/local/lib/yale-vpn
install -o root -g root -m 0755 \
  "$tmp/chromedriver/chromedriver-linux64/chromedriver" \
  /usr/local/lib/yale-vpn/chromedriver

install -o root -g root -m 0755 \
  "$root/lib/yale-management-route" \
  /usr/local/sbin/yale-management-route
install -o root -g root -m 0755 \
  "$root/lib/yale-vpn-dns" \
  /usr/local/sbin/yale-vpn-dns
install -o root -g root -m 0755 \
  "$root/lib/yale-sso-browser" \
  /usr/local/sbin/yale-sso-browser
install -o root -g root -m 0755 \
  "$root/lib/yale-vpn" \
  /usr/local/sbin/yale-vpn

install -d -o root -g root -m 0755 /etc/systemd/system
install -o root -g root -m 0644 /dev/stdin \
  /etc/systemd/system/yale-management-route.service <<'UNIT'
[Unit]
Description=Keep cloud SSH outside the Yale VPN tunnel
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/yale-management-route
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable --now yale-management-route.service

echo
echo "Installed. Verify SSH key access and password hardening, then run:"
echo "  sudo yale-vpn connect First.Last@yale.edu"
