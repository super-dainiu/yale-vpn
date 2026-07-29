# yale-vpn-bastion

A small, headless Yale VPN bastion for Ubuntu 24.04 on AWS.

It uses OpenConnect's AnyConnect protocol, a temporary headless Chrome session
for Yale's Microsoft/Duo SSO, policy routing that keeps inbound SSH alive when
the VPN installs a full default route, and Yale DNS for YCRC hostnames.

## What it protects

- Your Yale password exists only in the short-lived authentication processes.
- Chrome runs with a profile under `/run` and is killed after the VPN cookie is
  returned.
- The long-running OpenConnect process receives its cookie over stdin and does
  not inherit the Yale username or password.
- SSH replies use the original cloud gateway even while ordinary egress uses
  the Yale tunnel.

This does not make a shared account safe. Use one Unix account and one SSH key
per person, disable SSH passwords, and keep the cloud firewall as narrow as
practical.

## AWS

Create an x86-64 Ubuntu 24.04 Lightsail instance, attach a static IPv4, and
allow inbound TCP/22. A `/32` source rule is best for a fixed client IP. If
several users roam between networks, TCP/22 can be public only if SSH password
authentication is disabled and every user has a distinct public key.

Then connect to the instance and run:

```bash
git clone https://github.com/super-dainiu/yale-vpn-bastion.git
cd yale-vpn-bastion
sudo bash install.sh
sudo yale-vpn connect First.Last@yale.edu
```

Approve the Duo push. Check or stop the tunnel with:

```bash
sudo yale-vpn status
sudo yale-vpn disconnect
```

The installer supports Ubuntu 24.04 on x86-64. It installs OpenConnect, Google
Chrome, a matching ChromeDriver, Selenium, the management-route service, and
the four small scripts in `lib/`.

## YCRC SSH

Copy the relevant block from
[`examples/ssh_config`](examples/ssh_config) to `~/.ssh/config`, replace the
NetID, and create the control socket directory:

```bash
mkdir -p ~/.ssh/cm
chmod 700 ~/.ssh ~/.ssh/cm
ssh bouchet
```

Each cluster is a separate SSH server, so its first connection needs Duo.
Later `ssh`, `scp`, and `rsync` calls to the same host reuse that host's
ControlMaster while it remains alive.

## Notes

- Yale's current Linux user agent is
  `AnyConnect Linux_64 4.10.07061`.
- YCRC's internal DNS servers are configured only for `ycrc.yale.edu`.
- A reboot preserves the SSH management policy, but Yale SSO/Duo must be run
  again to recreate the VPN tunnel.
- Review the scripts before using them. Browser login flows can change.

## License

MIT
