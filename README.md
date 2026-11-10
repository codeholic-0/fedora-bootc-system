# zen-bootc

A personal Fedora 45 **bootc** OS image: fully-featured KDE Plasma appliance
— media codecs, full hardware support, basic utilities — no browser, no dev
toolchain, no Nix. Dev userland lives in distrobox.

Published at: `ghcr.io/codeholic-0/zen-bootc`

## Image variants

| Tag | Source file | Purpose |
|---|---|---|
| `testing` | `Containerfile.testing` | Worked-on variant; runs on the real machine. |
| `stable` / `latest` | `Containerfile` | Promoted variant (copy testing → Containerfile). |
| `minimal-latest` | `Containerfile.minimal` | Headless variant. |

`<role>-<YYYYMMDD>-<sha7>` tags are immutable rollback anchors.

## Pipeline

- Rechunked with [chunkah](https://github.com/coreos/chunkah) → ~128 layers;
  `bootc upgrade` pulls small deltas.
- Cosign-signed by digest ([`cosign.pub`](cosign.pub); `SIGNING_SECRET`).
- In-image enforcement: [`policy.json`](policy.json) +
  `registries.d/zen-bootc.yaml` require a valid signature for pulls of this
  repo only.
- `bootc container lint` as the final build step.
- Weekly rebuild (Sat ~18:05 UTC, `--pull=newer`) + path-filtered CI.
- Installer ISO (manual dispatch) → SourceForge. See [`docs/iso.md`](docs/iso.md).

## Usage

```bash
# switch (first install / replace base)
bootc switch --mutate-in-place --transport registry ghcr.io/codeholic-0/zen-bootc:testing

# update / rollback
bootc upgrade
bootc rollback            # or switch to a dated tag to pin further

# verify signature
cosign verify --key cosign.pub ghcr.io/codeholic-0/zen-bootc:testing
```

Installer ISO: Actions → "Publish ISO" (role dropdown), or
`gh workflow run iso-publish.yaml -f role=testing` — see
[`docs/iso.md`](docs/iso.md).

## Updates

```bash
zen-ctl check            # probe digest; also via /etc/cron.d/zen-ctl (Sat 22:00)
zen-ctl status           # tracking tag + running/staged digest + remote check
sudo zen-ctl upgrade     # stage an update (manual only)
sudo zen-ctl upgrade --apply
```

Applying is never automatic: cron runs `check` only; journal+wall announce
results.

## Repo layout

```
Containerfile{,.testing,.minimal}    image specs (promote: copy testing->Containerfile)
policy.json                          signed-ref policy shipped into the image
registries.d/                        registries.d snippet shipped into the image
disk_config/iso-kde.toml             bootc-image-builder config for the ISO
files/                               image-shipped files (zen-ctl, cron, drop-ins)
docs/iso.md                          ISO build + SourceForge guide
plymouth.toml                        boot kernel args
legacy/nix/                          dormant Nix-era leftovers; image has NO Nix
.github/workflows/bootc-publish.yaml CI: build -> chunkah rechunk -> push -> sign
.github/workflows/iso-publish.yaml   CI: role-choice ISO -> SourceForge (manual)
testing/                             work notes + reference clones (gitignored)
```

## Development loop

1. Edit `Containerfile.testing`, push, CI builds/signs `:testing`.
2. Test on the machine or via a role-`testing` ISO.
3. Proven → copy over `Containerfile`, push — that copy is the `stable`/`latest` release.
