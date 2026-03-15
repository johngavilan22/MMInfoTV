# USE NOW - MMInfoTV Quick Reference

Repo: https://github.com/johngavilan22/MMInfoTV

## Option A: Clone + run (recommended)

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

## Option B: Curl + run

```bash
curl -fsSL https://raw.githubusercontent.com/johngavilan22/MMInfoTV/main/bootstrap.sh | \
  bash -s -- \
  --template mm_rtsp \
  --platform linux-pc \
  --with-teslamate \
  --non-interactive \
  --base-url https://raw.githubusercontent.com/johngavilan22/MMInfoTV/main
```

## After install (Tesla)

- TeslaMate UI: `http://<host>:4000`
- Complete Tesla auth flow in TeslaMate UI
- Add snippet from `~/mm/tesla-module-snippet.js` into `~/MagicMirror/config/config.js`
- Grafana: `http://<host>:3000`

## Set secrets later (post-install)

```bash
bash ~/mm/install_magicmirror_pi.sh set-secrets --secrets-file ~/mm/secrets/mm_rtsp.secrets.json
```

## Secrets file format

```json
{
  "owmApiKey": "<OPENWEATHER_KEY>",
  "calendarIcsUrl": "<PRIVATE_ICS_URL>",
  "wallpaperSource": "<WALLPAPER_SOURCE>"
}
```
