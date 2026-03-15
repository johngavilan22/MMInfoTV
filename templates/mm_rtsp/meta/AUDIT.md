# mm_rtsp Template Audit (read-only pull)

Source host: `pi@192.168.1.234`
MagicMirror path: `~/MagicMirror`
Pulled on: 2026-03-15

## Captured baseline
- `config/config.js`
- `css/custom.css`

## Module repos + pinned commits
See: `modules/modules.lock.json`

## Local module overrides captured
These were modified on the source Pi and are included under `overrides/modules/`:

- `iFrame/iFrame.js`
- `iFrame/package.json`
- `iFrame/package-lock.json`
- `MMM-BackgroundSlideshow/MMM-BackgroundSlideshow.js`
- `MMM-BackgroundSlideshow/portrait/` (assets)
- `MMM-BackgroundSlideshow/usb/` (assets)
- `MMM-Remote-Control/modules.json`
- `MMM-RTSPStream/scripts/vlc.lua`
- `MMM-Wallpaper/node_helper.js`
- `MMM-Wallpaper/package-lock.json`
- `WallberryTheme/WB-clock/WB-clock.css`

## Notes
- Sensitive values in `config.js` were replaced with placeholders:
  - `__OWM_API_KEY__`
  - `__PRIVATE_CALENDAR_ICS_URL__`
- Set placeholders post-install with:
  - `bash ~/mm/install_magicmirror_pi.sh set-secrets --owm-api-key "<KEY>" --calendar-url "<ICS_URL>"`
- Installer applies modules from lock file first, then overlays these local override files.
