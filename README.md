# yale-vpn-bastion

A tiny Yale VPN jump host for Ubuntu 24.04.

## 1. Install

```bash
git clone https://github.com/super-dainiu/yale-vpn-bastion.git
cd yale-vpn-bastion
sudo bash install.sh
```

## 2. Connect

From your computer, forward OpenConnect's browser callback:

```bash
ssh -L '29786:[::1]:29786' ubuntu@BASTION_IP
```

Inside that SSH session:

```bash
sudo yale-vpn connect
```

Open the printed URL in your computer's browser, then finish Yale password and
Duo login. The browser redirects through the SSH tunnel and the VPN starts.

```bash
sudo yale-vpn status
sudo yale-vpn disconnect
```

No Yale password, private key, browser profile, or VPN cookie is stored.

## 3. SSH to YCRC

Copy [`ssh_config`](ssh_config) to `~/.ssh/config`, replace `BASTION_IP` and
`YOUR_NETID`, then:

```bash
mkdir -p ~/.ssh/cm
chmod 700 ~/.ssh ~/.ssh/cm
ssh yale-aws
ssh misha
```

Each YCRC host needs Duo once. Its ControlMaster then reuses that authenticated
connection.

## Why SSH stays alive

Yale VPN installs a full default route. `yale-vpn route` keeps replies from
port 22 on the original cloud gateway. A 5-second watchdog repairs the route
after DHCP changes, VPN reconnects, or unattended system upgrades.

The entire implementation is in two readable files:

- [`install.sh`](install.sh): packages and systemd units
- [`yale-vpn`](yale-vpn): route, watchdog, connect, status, disconnect

MIT licensed.
