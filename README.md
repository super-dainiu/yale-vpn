# yale-vpn

A tiny Yale VPN jump host for Ubuntu 24.04.

## 1. Install

```bash
git clone https://github.com/super-dainiu/yale-vpn.git
cd yale-vpn
sudo bash install.sh
```

## 2. Connect

```bash
ssh ubuntu@BASTION_IP
sudo yale-vpn connect First.Last@yale.edu
```

Enter the NetID password and approve Duo if prompted. A headless browser on the
bastion completes Yale's Microsoft/Duo flow and then exits.

```bash
sudo yale-vpn status
sudo yale-vpn disconnect
```

The password, temporary browser profile, and VPN cookie are not stored.

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

The entire implementation is in three readable files:

- [`install.sh`](install.sh): packages and systemd units
- [`yale-vpn`](yale-vpn): route, watchdog, connect, status, disconnect
- [`yale-sso-browser`](yale-sso-browser): Microsoft/Duo browser steps

MIT licensed.
