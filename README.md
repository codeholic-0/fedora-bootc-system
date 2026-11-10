# zen-bootc

A personal Fedora 45 **bootc** OS image: a fully-featured KDE Plasma appliance
— media codecs, full hardware support, basic utilities — with no browser, no
dev toolchain, and no Nix baked in. Dev userland (compilers, language SDKs)
lives in distrobox containers instead, keeping the base system pure.

Published at: `ghcr.io/codeholic-0/zen-bootc`

## Image variants

| Tag | Source file | Purpose |
|---|---|---|
| `testing` | `Containerfile.testing` | The continuously-worked variant. New things are tried here first; you run this on a real machine. |
| `stable` / `latest` | `Containerfile` | The promoted variant, updated by copying `Containerfile.testing` over it when testing is proven. |
| `minimal-latest` | `Containerfile.minimal` | Headless/bare bonus variant. |

Tags of the form `<role>-<YYYYMMDD>-<sha7>` (e.g. `testing-20261114-abc1234`)
are immutable per-build anchors — switch to one explicitly to time-travel.

## Pipeline features

- **Chunked updates**: every build is rechunked with
  [chunkah](https://github.com/coreos/chunkah) into ~128 layers, so
  `bootc upgrade` pulls small deltas instead of the whole image.
- **Signed images**: each build is cosign-signed by digest
  (key: [`cosign.pub`](cosign.pub); private key lives in the
  `SIGNING_SECRET` repo secret). `stable`/`latest` share one signature.
- **Client-side verification**: ships a scoped `containers` policy requiring
  a valid signature for pulls of this repo (`policy.json`,
  [`registries.d/zen-bootc.yaml`](registries.d/zen-bootc.yaml) enables the
  sigstore attachments for ghcr.io) — other pulls (distrobox etc.) stay
  default-allow. Built-in enforcement: no `/usr/etc` hacks.
- **Conformance lint**: `bootc container lint` runs as the final build step;
  the build fails on contract violations.
- **Weekly rebuild** (Saturday ~18:05 UTC) with `--pull=newer` so the image
  tracks Fedora 45 package updates without any commits.
- **Path-filtered CI**: pushing a change to one Containerfile rebuilds only
  that flavor.
- **Installer ISO** (optional, manual): a CI dispatch builds the testing or
  stable ISO (`-f role=…`) with
  [bootc-image-builder](https://github.com/osbuild/image-builder) and
  publishes it to
  [SourceForge](https://sourceforge.net/projects/fedora-bootc-system) with
  pinned SSH fingerprints and publication self-checks. See
  [`docs/iso.md`](docs/iso.md).

## Usage

### Deploy (first install / switch to this image)

On a running bootc system, switch the replaced base to this image:

```
bootc switch --mutate-in-place --transport registry ghcr.io/codeholic-0/zen-bootc:testing
```

### Update

The system tracks the tag you switched to:

```
bootc upgrade
```

Rollback: `bootc rollback` (in-place predecessor) or switch to an explicit
dated tag if you need to pin back further.

### Verify the current image

Signature verification is enforced in-image for `podman`/`bootc` pulls, but
you can check yourself too (from a distrobox/host shell with cosign):

```
cosign verify --key cosign.pub \
  ghcr.io/codeholic-0/zen-bootc:testing
```

### Installer ISO

Interactive Anaconda installer that installs `:testing` from GHCR at
install time. Build via CI (Actions → "Publish ISO", role dropdown or
`gh workflow run iso-publish.yaml -f role=testing`) or locally —
see [`docs/iso.md`](docs/iso.md).

## Repo layout

```
Containerfile{,.testing,.minimal}    image specs (promote: copy testing->Containerfile)
policy.json                          signed-ref policy shipped into the image
registries.d/                        registries.d snippet shipped into the image
disk_config/iso-kde.toml             bootc-image-builder config for the testing ISO
docs/iso.md                          ISO build + SourceForge publication guide
plymouth.toml                        boot kernel args
legacy/nix/                          dormant Nix-era leftovers; the image has NO Nix
.github/workflows/bootc-publish.yaml CI: build -> chunkah rechunk -> push -> sign
.github/workflows/iso-publish.yaml   CI: role-choice ISO -> SourceForge (manual dispatch)
testing/                             work notes + reference clones (gitignored)
```

## Development process

1. Edit `Containerfile.testing`, commit/push, let CI build/sign it.
2. Deploy/test `:testing` on the actual machine (or VM ISO).
3. When proven: copy `Containerfile.testing` over `Containerfile`, commit —
   CI then publishes it as `stable`/`latest`. That copy **is** the release.

Nothing here is declared for downstream reproduction yet beyond the contract
above — this stays a personal product until it formally isn't.
