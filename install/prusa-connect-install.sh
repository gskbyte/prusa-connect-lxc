#!/usr/bin/env bash

# Copyright (c) 2026 Jose Alcalá Correa
# Author: Jose Alcalá Correa
# SPDX-License-Identifier: GPL-3.0-only
# License: GPL-3.0-only | https://github.com/gskbyte/prusa-connect-lxc/blob/main/LICENSE
# Adapted from MIT-licensed templates by community-scripts ORG (Copyright (c) 2021-2026 community-scripts ORG)
# Source: https://github.com/prusa3d/prusa-connect

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

GH_INCLUDE_PRERELEASE=1 fetch_and_deploy_gh_release "prusa-connect" "prusa3d/prusa-connect" "singlefile" "latest" "/opt/prusa-connect" "prusa_connect_$(arch_resolve "amd64" "aarch64")"

msg_info "Configuring Prusa Connect"
mkdir -p /opt/prusa-connect_data
chmod 700 /opt/prusa-connect_data
ln -sf /opt/prusa-connect/prusa-connect /usr/local/bin/prusa-connect
msg_ok "Configured Prusa Connect"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/prusa-connect.service
[Unit]
Description=Prusa Connect Service
Wants=network-online.target
After=network-online.target
StartLimitIntervalSec=5min
StartLimitBurst=5

[Service]
Type=simple
User=root
UMask=0077
WorkingDirectory=/opt/prusa-connect_data
ExecStart=/opt/prusa-connect/prusa-connect
Restart=on-failure
RestartSec=5s
TimeoutStopSec=30s

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now prusa-connect
msg_ok "Created Service"

msg_info "Waiting for Prusa Connect Setup Code"
SETUP_CODE=""
for _ in {1..15}; do
  SETUP_CODE=$({ journalctl -u prusa-connect --no-pager 2>/dev/null || true; } | sed -n 's/.*setup_code=\([^[:space:]]*\).*/\1/p' | tail -n 1 | tr -d '"')
  [[ -n "$SETUP_CODE" ]] && break
  sleep 1
done
if [[ -n "$SETUP_CODE" ]]; then
  msg_ok "Prusa Connect Setup Code: ${SETUP_CODE}"
else
  msg_ok "Started Prusa Connect"
  msg_warn "Setup code not logged yet; run 'journalctl -u prusa-connect | grep setup_code | tail -n 1' inside the container."
fi

motd_ssh
customize
cleanup_lxc
