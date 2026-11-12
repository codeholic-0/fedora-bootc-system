# zen-bootc

A personal Fedora 45 **bootc** OS image: fully-featured KDE Plasma appliance
— media codecs, full hardware support, basic utilities — no browser, no dev
toolchain, no Nix. Tooling lives in the `dev` flavor and zen-dev, not here.

Published at: `ghcr.io/codeholic-0/zen-bootc`

## Image variants

| Tag | Source file | Purpose |
|---|---|---|
| `testing` | `Containerfile.testing` | Worked-on variant; runs on the real machine. |
| `stable` / `latest` | `Containerfile` | Promoted variant (copy testing → Containerfile). |
| `dev` | `Containerfile.dev` | Stable base + VSCodium + C/C++ toolchain (gcc/clang/gdb/valgrind/meson/ninja…), gh, neovim. Tracks stable, not testing. |
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

Installer ISO: Actions → "Publish ISO" (role checkboxes), or
`gh workflow run iso-publish.yaml -f stable=true -f dev=true` — see
[`docs/iso.md`](docs/iso.md).

## Updates

```bash
zen-ctl check            # probe digest; also via /etc/cron.d/zen-ctl (Sat 22:00)
zen-ctl status           # tracking tag + running/staged digest + remote check
zen-ctl upgrade          # stage an update (manual only)
zen-ctl upgrade --apply
zen-ctl switch           # browse stable|testing|dev tags, probe target, confirm → bootc switch
zen-ctl switch --list   # read-only listing, no elevation
```

Sudo is prompted automatically. Detection is cron-automated; applying is
always manual.

## zen-dev (user-local tooling)

`zen-dev` installs optional dev tooling into `$HOME` via each tool's official
upstream installer — never baked into the image, never touches `/usr`.
Fresh ISO installs ship it to `~/.local/bin` automatically; on any other
machine (incl. after `zen-ctl switch` between flavors):

```bash
curl -fsSL https://raw.githubusercontent.com/codeholic-0/zen-bootc/main/files/home/.local/bin/zen-dev-install.sh | bash
```

```bash
zen-dev            # list tools + install state
zen-dev brew       # Homebrew (official installer)
zen-dev idea       # IntelliJ IDEA CE (latest GitHub release)
zen-dev sdkman     # SDKMAN!
zen-dev nvm        # nvm (latest GitHub release)
zen-dev uv         # uv (official astral installer)
zen-dev rust       # rust (official rustup installer)
zen-dev update     # self-update zen-dev from this repo
```

Versions resolve live from upstream at install time — nothing pinned.
bash/zsh login shells get rc init lines automatically; other shells:
idea/uv/rust/brew work anywhere, sdkman/nvm abort.

## Repo layout

```
Containerfile{,.testing,.minimal,.dev} image specs (promote: copy testing->Containerfile)
policy.json                          signed-ref policy shipped into the image
registries.d/                        registries.d snippet shipped into the image
disk_config/iso-kde.toml             bootc-image-builder config for the ISO
files/                               shipped files (usr/local/bin/zen-ctl, cron, drop-ins; home/.local/bin/zen-dev = user-local tool)
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
