# MMInfoTV

MagicMirror bootstrap + templates (Raspberry Pi and Linux PC), with optional TeslaMate stack.

## Quick start (Git clone)
```bash
git clone https://github.com/johngavilan22/MMInfoTV.git ~/mm
cp ~/mm/secrets.example.json ~/mm/secrets/mm_rtsp.secrets.json
# edit secrets file values
bash ~/mm/install_magicmirror_pi.sh \
  --template mm_rtsp \
  --platform auto \
  --with-teslamate \
  --non-interactive \
  --secrets-file ~/mm/secrets/mm_rtsp.secrets.json
```

## Quick start (curl from GitHub raw)
```bash
curl -fsSL https://raw.githubusercontent.com/johngavilan22/MMInfoTV/main/bootstrap.sh | \
  bash -s -- \
  --template mm_rtsp \
  --platform linux-pc \
  --with-teslamate \
  --non-interactive \
  --base-url https://raw.githubusercontent.com/johngavilan22/MMInfoTV/main
```

## Tesla setup flow (no paid third-party)
1. Installer brings up Docker + TeslaMate stack (if `--with-teslamate` used)
2. Open TeslaMate UI: `http://<host>:4000`
3. Complete Tesla account auth/token flow in TeslaMate UI
4. TeslaMate publishes to MQTT (`localhost:1883`)
5. Installer installs `MMM-TeslaLogger` module for MagicMirror
6. Add snippet from `~/mm/tesla-module-snippet.js` into your `config.js` modules array

Also available:
- Grafana: `http://<host>:3000`

## Set secrets after install
```bash
bash ~/mm/install_magicmirror_pi.sh set-secrets --secrets-file ~/mm/secrets/mm_rtsp.secrets.json
# or explicitly:
# bash ~/mm/install_magicmirror_pi.sh set-secrets --owm-api-key "..." --calendar-url "..." --wallpaper-source "icloud:..."
```

## Repo contents
- `install_magicmirror_pi.sh` - main installer
- `bootstrap.sh` - curl entrypoint
- `templates/mm_rtsp/` - template source
- `templates/mm_rtsp.tgz` - template tarball for remote fetch mode
- `secrets.example.json` - sample secret values (safe to commit)

## Boot WiFi behavior
- On boot, `~/mm/configure-wifi.sh` runs before MagicMirror starts.
- It loops until internet connectivity is valid.
- If running interactively (TTY), it prompts for WiFi credentials and attempts setup via `nmcli` or `wpa_cli`.
- If non-interactive, it keeps retrying every 15 seconds until connected.

## Security
- Do **not** commit real secrets.
- Keep local secret files under `~/mm/secrets/` (ignored by `.gitignore`).
