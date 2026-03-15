#!/usr/bin/env bash
set -euo pipefail

# Curl entrypoint for GitHub-hosted installer.
# Example:
#   curl -fsSL https://raw.githubusercontent.com/johngavilan/MMInfoTV/main/bootstrap.sh | bash -s -- --template mm_rtsp

BASE_URL="${BASE_URL:-https://raw.githubusercontent.com/johngavilan22/MMInfoTV/main}"
TMP_SCRIPT="/tmp/install_magicmirror_pi.sh"

curl -fsSL "${BASE_URL%/}/install_magicmirror_pi.sh" -o "$TMP_SCRIPT"
chmod +x "$TMP_SCRIPT"

bash "$TMP_SCRIPT" "$@"
