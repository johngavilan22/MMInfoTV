# MMInfoTV

MagicMirror Raspberry Pi bootstrap + templates.

## Quick start (Git clone)
```bash
git clone https://github.com/johngavilan22/MMInfoTV.git ~/mm
cp ~/mm/secrets.example.json ~/mm/secrets/mm_rtsp.secrets.json
# edit secrets file values
bash ~/mm/install_magicmirror_pi.sh --template mm_rtsp --non-interactive --secrets-file ~/mm/secrets/mm_rtsp.secrets.json
```

## Quick start (curl from GitHub raw)
```bash
curl -fsSL https://raw.githubusercontent.com/johngavilan/MMInfoTV/main/bootstrap.sh | \
  bash -s -- --template mm_rtsp --non-interactive --base-url https://raw.githubusercontent.com/johngavilan/MMInfoTV/main
```

## Set secrets after install
```bash
bash ~/mm/install_magicmirror_pi.sh set-secrets --secrets-file ~/mm/secrets/mm_rtsp.secrets.json
```

## Repo contents
- `install_magicmirror_pi.sh` - main installer
- `bootstrap.sh` - curl entrypoint
- `templates/mm_rtsp/` - template source
- `templates/mm_rtsp.tgz` - template tarball for remote fetch mode
- `secrets.example.json` - sample secret values (safe to commit)

## Security
- Do **not** commit real secrets.
- Keep local secret files under `~/mm/secrets/` (ignored by `.gitignore`).
.
