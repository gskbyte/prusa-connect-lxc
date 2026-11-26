#!/usr/bin/env bash
_CS_DEFAULT_URL="${PRUSA_CONNECT_REPO_URL:-https://raw.githubusercontent.com/gskbyte/prusa-connect-lxc/main}"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2026 Jose Alcalá Correa
# Author: Jose Alcalá Correa
# SPDX-License-Identifier: GPL-3.0-only
# License: GPL-3.0-only | https://github.com/gskbyte/prusa-connect-lxc/blob/main/LICENSE
# Adapted from MIT-licensed templates by community-scripts ORG (Copyright (c) 2021-2026 community-scripts ORG)
# Source: https://github.com/prusa3d/prusa-connect

APP="Prusa-Connect"
var_tags="${var_tags:-3d-printing;iot}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
#var_arm64="${var_arm64:-no}" # unset = ask the user; set yes/no only when verified
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -f /opt/prusa-connect/prusa-connect ]]; then
    msg_error "No Prusa Connect Installation Found!"
    exit
  fi

  if GH_INCLUDE_PRERELEASE=1 check_for_gh_release "prusa-connect" "prusa3d/prusa-connect"; then
    msg_info "Stopping Prusa Connect"
    systemctl stop prusa-connect
    msg_ok "Stopped Prusa Connect"

    PREV_VERSION=""
    if [[ -f ~/.prusa-connect ]]; then
      PREV_VERSION=$(<~/.prusa-connect)
    fi
    cp -a /opt/prusa-connect/prusa-connect /opt/prusa-connect/prusa-connect.bak

    if ! GH_INCLUDE_PRERELEASE=1 fetch_and_deploy_gh_release "prusa-connect" "prusa3d/prusa-connect" "singlefile" "latest" "/opt/prusa-connect" "prusa_connect_$(arch_resolve "amd64" "aarch64")"; then
      rm -f /opt/prusa-connect/prusa-connect.bak
      systemctl start prusa-connect || true
      exit 1
    fi

    msg_info "Starting Prusa Connect"
    systemctl start prusa-connect || true
    READY=0
    for _ in {1..30}; do
      if systemctl is-active --quiet prusa-connect && (cd /opt/prusa-connect_data && /opt/prusa-connect/prusa-connect core healthcheck >/dev/null 2>&1); then
        READY=1
        break
      fi
      if systemctl is-failed --quiet prusa-connect; then
        break
      fi
      sleep 2
    done
    if ((READY)); then
      rm -f /opt/prusa-connect/prusa-connect.bak
      msg_ok "Started Prusa Connect"
      msg_ok "Updated successfully!"
    else
      msg_error "Prusa Connect failed health check after update; rolling back binary"
      systemctl stop prusa-connect || true
      mv -f /opt/prusa-connect/prusa-connect.bak /opt/prusa-connect/prusa-connect
      if [[ -n "$PREV_VERSION" ]]; then
        echo "$PREV_VERSION" >~/.prusa-connect
      else
        rm -f ~/.prusa-connect
      fi
      rm -f ~/.prusa-connect.pending
      if systemctl start prusa-connect; then
        msg_warn "Rolled back Prusa Connect binary to ${PREV_VERSION:-previous version}. Check logs: journalctl -u prusa-connect -n 50 --no-pager"
      else
        msg_error "Rollback failed to start Prusa Connect; restore from a Proxmox snapshot or backup."
      fi
      exit 1
    fi
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:8080${CL}"
echo -e "${INFO}${YW}If you need the setup code again: journalctl -u prusa-connect | grep setup_code | tail -n 1${CL}"
