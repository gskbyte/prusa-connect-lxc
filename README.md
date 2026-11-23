# Prusa Connect LXC

This repository contains Proxmox VE helper scripts for a local Prusa Connect server. Each file follows the `community-scripts/DevScripts` format. The CT script creates an unprivileged LXC container with Debian 13 and installs the official Prusa Connect binary.

A pull request to `community-scripts/DevScripts` is not possible yet. For a new script, the upstream repository must have a minimum of 1,000 GitHub stars and an age of 6 months or more. The `prusa3d/prusa-connect` repository does not have 1,000 stars or 6 months of age yet, and it has beta pre-releases only.

## Install

Run this command in the Proxmox VE host shell:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/gskbyte/prusa-connect-lxc/main/ct/prusa-connect.sh)"
```

If you install from another branch or fork, set `PRUSA_CONNECT_REPO_URL` before the command:

```bash
PRUSA_CONNECT_REPO_URL="https://raw.githubusercontent.com/gskbyte/prusa-connect-lxc/<branch>" bash -c "$(curl -fsSL https://raw.githubusercontent.com/gskbyte/prusa-connect-lxc/<branch>/ct/prusa-connect.sh)"
```

## Complete the First-Run Setup

The install script shows the one-time setup code after the service starts.

1. Copy the setup code from the install output.
2. Open `http://<container-ip>:8080` in a web browser.
3. Enter the setup code.
4. Complete the setup wizard.

If the container restarts before you complete the wizard, read the new setup code in the container console:

```bash
journalctl -u prusa-connect | grep setup_code | tail -n 1
```

## Update Prusa Connect

Prusa Connect ships frequent beta releases on GitHub. The CT script tracks both pre-releases and stable releases from `prusa3d/prusa-connect`. All persistent data stays in `/opt/prusa-connect_data`, separate from the binary in `/opt/prusa-connect`.

> [!CAUTION]
> Before you update Prusa Connect, make a backup of the LXC container or `/opt/prusa-connect_data`. Prusa Connect is in public beta.

1. Open the LXC container console.
2. Run the `update` command:

```bash
update
```

## Repository Files

- `ct/prusa-connect.sh`: Creates the LXC container on a Proxmox VE host and updates Prusa Connect inside the container.
- `install/prusa-connect-install.sh`: Downloads the Prusa Connect binary, creates the data directory, and sets up the systemd service.
- `json/prusa-connect.json`: Defines the catalog metadata for the container.

## Test Local Changes

If you test local edits on a Proxmox VE host, run the CT script from the repository directory:

```bash
bash ct/prusa-connect.sh
```

> [!NOTE]
> When you run `ct/prusa-connect.sh` from a local copy of this repository, the script loads `install/prusa-connect-install.sh` from the same directory.

If you test an update with local edits, run these commands on the Proxmox VE host:

```bash
pct push <CTID> ct/prusa-connect.sh /tmp/prusa-connect.sh
pct exec <CTID> -- bash /tmp/prusa-connect.sh
```

## Paths and Service

| Item | Path or Address |
| --- | --- |
| Binary | `/opt/prusa-connect/prusa-connect` (symbolic link at `/usr/local/bin/prusa-connect`) |
| Data directory | `/opt/prusa-connect_data` |
| Optional config file | `/opt/prusa-connect_data/config/config.yaml` |
| Systemd unit | `/etc/systemd/system/prusa-connect.service` |
| Web interface | `http://<container-ip>:8080` |
| Installed version file | `/root/.prusa-connect` |
