#!/usr/bin/env bash
set -euo pipefail

MM_DIR="${HOME}/MagicMirror"
MM_ARTIFACTS_DIR="${HOME}/mm"
MM_TEMPLATES_DIR="${MM_ARTIFACTS_DIR}/templates"
MM_REPO="https://github.com/MagicMirrorOrg/MagicMirror.git"
MM_BRANCH="master"
NODE_MAJOR="20"

COMMAND="install"
MM_TEMPLATE="default"
PLATFORM="auto"          # auto|pi|linux-pc
ROTATION="left"          # left|right
BASE_URL=""
OWM_API_KEY=""
CALENDAR_ICS_URL=""
WALLPAPER_SOURCE=""
CONFIG_PATH=""
SECRETS_FILE=""
NON_INTERACTIVE="false"

WITH_TESLAMATE="false"
TESLAMATE_DIR="${MM_ARTIFACTS_DIR}/teslamate"
TESLAMATE_TZ="America/Chicago"

DETECTED_PLATFORM=""
BROWSER_BIN=""
COMPOSE_CMD=""

log() { echo "[mm-install] $*"; }
err() { echo "[mm-install][error] $*" >&2; }

usage() {
  cat <<'EOF'
MagicMirror installer (Pi + Linux PC)

USAGE
  install_magicmirror_pi.sh [install] [options]
  install_magicmirror_pi.sh set-secrets [options]

COMMANDS
  install (default)
    --template <name>        Template name (default|mm_rtsp)
    --platform <auto|pi|linux-pc>
    --rotation <left|right>  Screen rotation (default: left)
    --base-url <url>         Optional URL where templates are hosted
    --secrets-file <path>    JSON file with secrets to inject post-install
    --with-teslamate         Install Docker + TeslaMate stack + MMM-TeslaLogger
    --teslamate-dir <path>   TeslaMate stack directory (default: ~/mm/teslamate)
    --teslamate-tz <tz>      TeslaMate timezone (default: America/Chicago)
    --non-interactive        Fail instead of prompting (sudo/password-safe mode)

  set-secrets
    --owm-api-key <key>      OpenWeather API key to inject
    --calendar-url <url>     Private ICS calendar URL to inject
    --wallpaper-source <src> Wallpaper source (e.g. icloud:...)
    --secrets-file <path>    JSON keys: owmApiKey, calendarIcsUrl, wallpaperSource
    --config <path>          Optional config path (default: ~/MagicMirror/config/config.js)

EXAMPLES
  bash ~/mm/install_magicmirror_pi.sh --template mm_rtsp --platform auto
  bash ~/mm/install_magicmirror_pi.sh --template mm_rtsp --with-teslamate --non-interactive
  bash ~/mm/install_magicmirror_pi.sh set-secrets --secrets-file ~/mm/secrets/mm_rtsp.secrets.json
EOF
}

enable_noninteractive_env() {
  if [[ "$NON_INTERACTIVE" == "true" ]]; then
    export DEBIAN_FRONTEND=noninteractive
    export APT_LISTCHANGES_FRONTEND=none
    export NEEDRESTART_MODE=a
  fi
}

require_sudo() {
  if [[ "$NON_INTERACTIVE" == "true" ]]; then
    sudo -n true 2>/dev/null || {
      err "--non-interactive set, but sudo requires a password. Pre-authorize sudo first."
      exit 1
    }
  else
    if ! sudo -n true 2>/dev/null; then
      log "Sudo required; you may be prompted."
    fi
  fi
}

detect_platform() {
  if [[ "$PLATFORM" != "auto" ]]; then
    DETECTED_PLATFORM="$PLATFORM"
    return
  fi

  local arch model
  arch="$(uname -m)"
  model="$(tr -d '\0' </proc/device-tree/model 2>/dev/null || true)"

  if [[ "$arch" == "armv7l" || "$arch" == "aarch64" || "$model" == *"Raspberry Pi"* ]]; then
    DETECTED_PLATFORM="pi"
  else
    DETECTED_PLATFORM="linux-pc"
  fi

  log "Auto-detected platform: ${DETECTED_PLATFORM}"
}

resolve_browser_bin() {
  if command -v chromium-browser >/dev/null 2>&1; then
    BROWSER_BIN="chromium-browser"
  elif command -v chromium >/dev/null 2>&1; then
    BROWSER_BIN="chromium"
  elif command -v google-chrome >/dev/null 2>&1; then
    BROWSER_BIN="google-chrome"
  else
    BROWSER_BIN="chromium-browser"
  fi
  log "Using kiosk browser: ${BROWSER_BIN}"
}

install_base_packages() {
  log "Installing system packages for ${DETECTED_PLATFORM}..."
  sudo apt-get update -y

  local browser_pkg="chromium-browser"
  if apt-cache show chromium-browser >/dev/null 2>&1; then
    browser_pkg="chromium-browser"
  elif apt-cache show chromium >/dev/null 2>&1; then
    browser_pkg="chromium"
  fi

  sudo apt-get install -y \
    git curl wget ca-certificates jq tar \
    build-essential python3 python3-pip \
    "$browser_pkg" unclutter x11-xserver-utils
}

install_node() {
  if command -v node >/dev/null 2>&1; then
    local current_major
    current_major="$(node -v | sed 's/v\([0-9]*\).*/\1/')"
    if [[ "$current_major" -ge "$NODE_MAJOR" ]]; then
      log "Node already installed: $(node -v)"
      return
    fi
  fi

  log "Installing Node.js ${NODE_MAJOR}.x..."
  curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | sudo -E bash -
  sudo apt-get install -y nodejs
}

install_magicmirror() {
  log "Installing MagicMirror into ${MM_DIR}..."
  if [[ ! -d "${MM_DIR}/.git" ]]; then
    git clone --depth 1 --branch "${MM_BRANCH}" "${MM_REPO}" "${MM_DIR}"
  else
    git -C "${MM_DIR}" fetch --depth 1 origin "${MM_BRANCH}"
    git -C "${MM_DIR}" checkout "${MM_BRANCH}"
    git -C "${MM_DIR}" reset --hard "origin/${MM_BRANCH}"
  fi

  (cd "${MM_DIR}" && npm install --only=prod)
}

write_default_configs() {
  mkdir -p "${MM_ARTIFACTS_DIR}" "${MM_DIR}/config" "${MM_DIR}/css"

  cat > "${MM_ARTIFACTS_DIR}/config.js" <<'EOF'
let config = {
  address: "0.0.0.0",
  port: 8080,
  ipWhitelist: [],
  language: "en",
  units: "imperial",
  timeFormat: 12,
  modules: [
    { module: "alert" },
    { module: "clock", position: "top_left" },
    { module: "compliments", position: "lower_third" }
  ]
};
if (typeof module !== "undefined") {module.exports = config;}
EOF

  cat > "${MM_ARTIFACTS_DIR}/custom.css" <<'EOF'
body { zoom: 0.95; }
EOF

  cp "${MM_ARTIFACTS_DIR}/config.js" "${MM_DIR}/config/config.js"
  cp "${MM_ARTIFACTS_DIR}/custom.css" "${MM_DIR}/css/custom.css"
}

install_modules_from_lock() {
  local lock_file="$1"
  local modules_dir="${MM_DIR}/modules"
  mkdir -p "${modules_dir}"

  jq -c '.[]' "$lock_file" | while read -r row; do
    local name repo commit
    name="$(echo "$row" | jq -r '.name')"
    repo="$(echo "$row" | jq -r '.repo')"
    commit="$(echo "$row" | jq -r '.commit')"

    log "Module: ${name} @ ${commit}"
    if [[ ! -d "${modules_dir}/${name}/.git" ]]; then
      git clone "$repo" "${modules_dir}/${name}"
    fi
    git -C "${modules_dir}/${name}" fetch --all --tags
    git -C "${modules_dir}/${name}" checkout "$commit"

    if [[ -f "${modules_dir}/${name}/package.json" ]]; then
      (cd "${modules_dir}/${name}" && npm install --omit=dev || true)
    fi
  done
}

fetch_template_if_needed() {
  local tdir="${MM_TEMPLATES_DIR}/${MM_TEMPLATE}"
  [[ -d "$tdir" ]] && return 0
  [[ -z "$BASE_URL" ]] && return 0

  mkdir -p "${MM_TEMPLATES_DIR}"
  local tgz="${MM_TEMPLATES_DIR}/${MM_TEMPLATE}.tgz"
  local url="${BASE_URL%/}/templates/${MM_TEMPLATE}.tgz"
  log "Template ${MM_TEMPLATE} missing locally; fetching ${url}"
  curl -fsSL "$url" -o "$tgz"
  mkdir -p "$tdir"
  tar xzf "$tgz" -C "$tdir" --strip-components=1
}

apply_template() {
  fetch_template_if_needed
  local tdir="${MM_TEMPLATES_DIR}/${MM_TEMPLATE}"
  if [[ ! -d "$tdir" ]]; then
    log "Template '${MM_TEMPLATE}' not found. Keeping default config."
    return
  fi

  log "Applying template: ${MM_TEMPLATE}"

  [[ -f "${tdir}/config/config.js" ]] && cp "${tdir}/config/config.js" "${MM_DIR}/config/config.js" && cp "${tdir}/config/config.js" "${MM_ARTIFACTS_DIR}/config.js"
  [[ -f "${tdir}/css/custom.css" ]] && cp "${tdir}/css/custom.css" "${MM_DIR}/css/custom.css" && cp "${tdir}/css/custom.css" "${MM_ARTIFACTS_DIR}/custom.css"
  [[ -f "${tdir}/modules/modules.lock.json" ]] && install_modules_from_lock "${tdir}/modules/modules.lock.json"
  [[ -d "${tdir}/overrides/modules" ]] && cp -R "${tdir}/overrides/modules/." "${MM_DIR}/modules/"

  mkdir -p "${MM_ARTIFACTS_DIR}/templates/${MM_TEMPLATE}"
  cp -R "${tdir}/." "${MM_ARTIFACTS_DIR}/templates/${MM_TEMPLATE}/"
}

configure_pm2_autostart() {
  log "Configuring PM2 startup..."
  sudo npm install -g pm2

  cat > "${MM_ARTIFACTS_DIR}/mm-start.sh" <<EOF
#!/usr/bin/env bash
set -e
export DISPLAY=:0
OUTPUT=\$(xrandr --query 2>/dev/null | awk '/ connected primary/{print \$1; exit}')
[ -z "\$OUTPUT" ] && OUTPUT=\$(xrandr --query 2>/dev/null | awk '/ connected/{print \$1; exit}')
xrandr --output "\${OUTPUT:-HDMI-1}" --rotate ${ROTATION} || true
unclutter -idle 0.5 -root || true
${BROWSER_BIN} --kiosk --noerrdialogs --disable-infobars --incognito http://localhost:8080 &
cd "${MM_DIR}"
node serveronly
EOF
  chmod +x "${MM_ARTIFACTS_DIR}/mm-start.sh"

  pm2 delete magicmirror >/dev/null 2>&1 || true
  pm2 start "${MM_ARTIFACTS_DIR}/mm-start.sh" --name magicmirror
  pm2 save
  pm2 startup systemd -u "$USER" --hp "$HOME" | sed 's/^/[mm-install] /'
}

# --- TeslaMate / Docker integration ---
setup_compose_cmd() {
  if docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
  elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
  else
    err "Docker Compose not found after install."
    exit 1
  fi
}

install_docker_prereqs() {
  if command -v docker >/dev/null 2>&1; then
    log "Docker already installed"
  else
    log "Installing Docker..."
    sudo apt-get update -y
    sudo apt-get install -y docker.io docker-compose-plugin || {
      log "Apt Docker install failed; using get.docker.com"
      curl -fsSL https://get.docker.com | sudo sh
    }
  fi

  sudo systemctl enable docker || true
  sudo systemctl start docker || true
  sudo usermod -aG docker "$USER" || true
  setup_compose_cmd
}

rand_hex() {
  python3 - <<'PY'
import secrets
print(secrets.token_hex(16))
PY
}

write_teslamate_stack() {
  mkdir -p "${TESLAMATE_DIR}"

  local db_pass mqtt_pass
  db_pass="$(rand_hex)"
  mqtt_pass="$(rand_hex)"

  cat > "${TESLAMATE_DIR}/.env" <<EOF
TM_TZ=${TESLAMATE_TZ}
TM_DB_NAME=teslamate
TM_DB_USER=teslamate
TM_DB_PASSWORD=${db_pass}
TM_DB_HOST=database
TM_ENCRYPTION_KEY=$(rand_hex)
TM_MQTT_HOST=mosquitto
TM_MQTT_USERNAME=teslamate
TM_MQTT_PASSWORD=${mqtt_pass}
EOF

  cat > "${TESLAMATE_DIR}/docker-compose.yml" <<'EOF'
services:
  database:
    image: postgres:17
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${TM_DB_USER}
      POSTGRES_PASSWORD: ${TM_DB_PASSWORD}
      POSTGRES_DB: ${TM_DB_NAME}
    volumes:
      - teslamate-db:/var/lib/postgresql/data

  mosquitto:
    image: eclipse-mosquitto:2
    restart: unless-stopped
    ports:
      - "1883:1883"
    volumes:
      - ./mosquitto.conf:/mosquitto/config/mosquitto.conf:ro

  teslamate:
    image: teslamate/teslamate:latest
    restart: unless-stopped
    depends_on:
      - database
      - mosquitto
    environment:
      ENCRYPTION_KEY: ${TM_ENCRYPTION_KEY}
      DATABASE_USER: ${TM_DB_USER}
      DATABASE_PASS: ${TM_DB_PASSWORD}
      DATABASE_NAME: ${TM_DB_NAME}
      DATABASE_HOST: ${TM_DB_HOST}
      MQTT_HOST: ${TM_MQTT_HOST}
      MQTT_USERNAME: ${TM_MQTT_USERNAME}
      MQTT_PASSWORD: ${TM_MQTT_PASSWORD}
      TZ: ${TM_TZ}
    ports:
      - "4000:4000"

  grafana:
    image: teslamate/grafana:latest
    restart: unless-stopped
    depends_on:
      - database
    environment:
      DATABASE_USER: ${TM_DB_USER}
      DATABASE_PASS: ${TM_DB_PASSWORD}
      DATABASE_NAME: ${TM_DB_NAME}
      DATABASE_HOST: ${TM_DB_HOST}
    ports:
      - "3000:3000"

volumes:
  teslamate-db:
EOF

  cat > "${TESLAMATE_DIR}/mosquitto.conf" <<'EOF'
allow_anonymous true
listener 1883
EOF

  cat > "${TESLAMATE_DIR}/README.md" <<'EOF'
# TeslaMate stack

1) Start stack:
   docker compose up -d

2) Open TeslaMate:
   http://<host-ip>:4000

3) Add Tesla account via TeslaMate UI (token login flow)

4) MQTT broker available on :1883
   MagicMirror MMM-TeslaLogger can subscribe to topic `teslamate/cars/1/+`

Grafana:
- http://<host-ip>:3000
EOF
}

start_teslamate_stack() {
  log "Starting TeslaMate stack in ${TESLAMATE_DIR}"
  (cd "${TESLAMATE_DIR}" && ${COMPOSE_CMD} up -d)
}

install_mmm_teslalogger_module() {
  local modules_dir="${MM_DIR}/modules"
  mkdir -p "${modules_dir}"

  if [[ ! -d "${modules_dir}/MMM-TeslaLogger/.git" ]]; then
    git clone https://github.com/spitzlbergerj/MMM-TeslaLogger.git "${modules_dir}/MMM-TeslaLogger"
  fi
  (cd "${modules_dir}/MMM-TeslaLogger" && npm install --omit=dev || true)
}

write_tesla_snippet() {
  cat > "${MM_ARTIFACTS_DIR}/tesla-module-snippet.js" <<'EOF'
{
  module: 'MMM-TeslaLogger',
  position: 'top_right',
  header: 'Tesla',
  config: {
    mqttServerAddress: '127.0.0.1',
    mqttServerPort: '1883',
    mqttTopics: [
      'Tesla',
      'teslamate/cars/1/+'
    ],
    style: 'lines',
    displayBattery_level: true,
    displayState: true,
    displayCharger_actual_current: true,
    displayOutside_temp: true,
    displayInside_temperature: true,
    displaySentry_mode: true
  }
},
EOF
}

configure_tesla_stack() {
  install_docker_prereqs
  write_teslamate_stack
  start_teslamate_stack
  install_mmm_teslalogger_module
  write_tesla_snippet

  log "TeslaMate + MMM-TeslaLogger installed."
  log "Complete Tesla auth in browser: http://localhost:4000"
  log "Then add snippet from ${MM_ARTIFACTS_DIR}/tesla-module-snippet.js into config.js modules array."
  log "NOTE: log out and back in (or reboot) for docker group membership to apply for non-sudo docker commands."
}

escape_sed() {
  printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'
}

load_secrets_file() {
  [[ -z "$SECRETS_FILE" ]] && return 0
  [[ -f "$SECRETS_FILE" ]] || { err "Secrets file not found: $SECRETS_FILE"; exit 1; }

  [[ -z "$OWM_API_KEY" ]] && OWM_API_KEY="$(jq -r '.owmApiKey // empty' "$SECRETS_FILE")"
  [[ -z "$CALENDAR_ICS_URL" ]] && CALENDAR_ICS_URL="$(jq -r '.calendarIcsUrl // empty' "$SECRETS_FILE")"
  [[ -z "$WALLPAPER_SOURCE" ]] && WALLPAPER_SOURCE="$(jq -r '.wallpaperSource // empty' "$SECRETS_FILE")"
}

set_secrets() {
  load_secrets_file

  local config_path="${MM_DIR}/config/config.js"
  [[ -n "$CONFIG_PATH" ]] && config_path="$CONFIG_PATH"
  [[ -f "$config_path" ]] || { err "Config not found: $config_path"; exit 1; }

  if [[ -n "$OWM_API_KEY" ]]; then
    local key_esc
    key_esc="$(escape_sed "$OWM_API_KEY")"
    sed -i.bak "s/__OWM_API_KEY__/${key_esc}/g" "$config_path"
    log "Injected OpenWeather API key"
  fi

  if [[ -n "$CALENDAR_ICS_URL" ]]; then
    local cal_esc
    cal_esc="$(escape_sed "$CALENDAR_ICS_URL")"
    sed -i.bak "s#__PRIVATE_CALENDAR_ICS_URL__#${cal_esc}#g" "$config_path"
    log "Injected private calendar URL"
  fi

  if [[ -n "$WALLPAPER_SOURCE" ]]; then
    local wp_esc
    wp_esc="$(escape_sed "$WALLPAPER_SOURCE")"
    sed -i.bak "s#__WALLPAPER_SOURCE__#${wp_esc}#g" "$config_path"
    log "Injected wallpaper source"
  fi

  if [[ -z "$OWM_API_KEY" && -z "$CALENDAR_ICS_URL" && -z "$WALLPAPER_SOURCE" ]]; then
    err "No secrets provided. Use --secrets-file or --owm-api-key/--calendar-url/--wallpaper-source"
    exit 1
  fi

  log "Secrets applied to ${config_path} (backup: ${config_path}.bak)"
}

write_readme() {
  cat > "${MM_ARTIFACTS_DIR}/README.md" <<EOF
# MagicMirror Bootstrap Artifacts

Template used: ${MM_TEMPLATE}
Platform: ${DETECTED_PLATFORM}

Install:
  bash ~/mm/install_magicmirror_pi.sh --template ${MM_TEMPLATE} --platform ${DETECTED_PLATFORM}

Set secrets after install:
  bash ~/mm/install_magicmirror_pi.sh set-secrets --secrets-file ~/mm/secrets/${MM_TEMPLATE}.secrets.json

TeslaMate (if enabled):
  Stack dir: ${TESLAMATE_DIR}
  TeslaMate UI: http://localhost:4000
  Grafana: http://localhost:3000
  MQTT: localhost:1883
EOF
}

parse_args() {
  if [[ $# -gt 0 ]]; then
    case "$1" in
      install|set-secrets|help|-h|--help)
        COMMAND="$1"
        shift
        ;;
    esac
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --template) MM_TEMPLATE="$2"; shift 2 ;;
      --platform) PLATFORM="$2"; shift 2 ;;
      --rotation) ROTATION="$2"; shift 2 ;;
      --base-url) BASE_URL="$2"; shift 2 ;;
      --owm-api-key) OWM_API_KEY="$2"; shift 2 ;;
      --calendar-url) CALENDAR_ICS_URL="$2"; shift 2 ;;
      --wallpaper-source) WALLPAPER_SOURCE="$2"; shift 2 ;;
      --secrets-file) SECRETS_FILE="$2"; shift 2 ;;
      --config) CONFIG_PATH="$2"; shift 2 ;;
      --with-teslamate) WITH_TESLAMATE="true"; shift ;;
      --teslamate-dir) TESLAMATE_DIR="$2"; shift 2 ;;
      --teslamate-tz) TESLAMATE_TZ="$2"; shift 2 ;;
      --non-interactive) NON_INTERACTIVE="true"; shift ;;
      -h|--help) COMMAND="help"; shift ;;
      *) err "Unknown arg: $1"; usage; exit 1 ;;
    esac
  done
}

run_install() {
  enable_noninteractive_env
  require_sudo
  detect_platform
  resolve_browser_bin

  mkdir -p "${MM_ARTIFACTS_DIR}"
  install_base_packages
  install_node
  install_magicmirror
  write_default_configs
  apply_template
  configure_pm2_autostart

  if [[ "$WITH_TESLAMATE" == "true" ]]; then
    configure_tesla_stack
  fi

  if [[ -n "$SECRETS_FILE" || -n "$OWM_API_KEY" || -n "$CALENDAR_ICS_URL" || -n "$WALLPAPER_SOURCE" ]]; then
    set_secrets
  fi

  write_readme
  log "Done. Artifacts saved in ${MM_ARTIFACTS_DIR}"
}

main() {
  parse_args "$@"
  case "$COMMAND" in
    help) usage ;;
    install) run_install ;;
    set-secrets) set_secrets ;;
    *) err "Unknown command: $COMMAND"; usage; exit 1 ;;
  esac
}

main "$@"
