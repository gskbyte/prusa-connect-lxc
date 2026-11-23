#!/usr/bin/env bash
_CS_DEFAULT_URL="${PRUSA_CONNECT_REPO_URL:-https://raw.githubusercontent.com/gskbyte/prusa-connect-lxc/main}"
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Jose Alcalá Correa
# License: MIT | https://github.com/community-scripts/DevScripts/raw/main/LICENSE
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

    GH_INCLUDE_PRERELEASE=1 fetch_and_deploy_gh_release "prusa-connect" "prusa3d/prusa-connect" "singlefile" "latest" "/opt/prusa-connect" "prusa_connect_$(arch_resolve "amd64" "aarch64")"

    msg_info "Starting Prusa Connect"
    systemctl start prusa-connect
    msg_ok "Started Prusa Connect"
    msg_ok "Updated successfully!"
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
echo -e "${INFO}${YW}First-run setup code: journalctl -u prusa-connect | grep setup_code | tail -n 1${CL}"
