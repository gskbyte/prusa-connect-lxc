#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Jose Alcalá Correa
# License: MIT | https://github.com/community-scripts/DevScripts/raw/main/LICENSE
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

motd_ssh
customize
cleanup_lxc
