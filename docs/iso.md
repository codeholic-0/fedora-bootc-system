# Installer ISO

Manual-dispatch CI builds a bootable network-installer ISO and publishes it to
SourceForge. Config: `disk_config/iso-kde.toml`.

## CI

```bash
gh workflow run iso-publish.yaml --ref main -f testing=true          # one
gh workflow run iso-publish.yaml --ref main -f stable=true -f dev=true   # two
gh workflow run iso-publish.yaml --ref main -f testing=true -f stable=true -f dev=true  # all three
```

Roles are flags: any subset builds concurrently (one matrix leg per role,
own runner each; untouched roles cost nothing). The Actions UI exposes the
same three checkboxes.

- Press only when the latest image run is green and signed; the workflow
  cosign-verifies the tag first and the ISO installs that tag at boot.
- Output (run summary has the URL):
  `https://sourceforge.net/projects/zen-bootc/files/<YYYY-MM-DD>/zen-bootc-<role>-<YYYYMMDD>-<sha7>.iso/download`
- Each ISO ships its own `<name>.iso.sha256` beside it (verify with
  `sha256sum -c <name>.iso.sha256`).
- Secrets: `SF_SSH_PRIVATE_KEY`, `SF_USERNAME`.
- Known constraints: runner pinned to `ubuntu-24.04` (26.04 AppArmor breaks
  osbuild mounts); BIB pinned by digest; frs accepts rsync/sftp only.

## Local build

```bash
sudo podman pull ghcr.io/codeholic-0/zen-bootc:testing
mkdir -p output
sudo podman run --rm -it --privileged \
  -v "$(pwd)/output:/output" \
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  -v "$(pwd)/disk_config/iso-kde.toml:/config.toml:ro" \
  quay.io/centos-bootc/bootc-image-builder:latest \
  --rootfs ext4 --type anaconda-iso \
  ghcr.io/codeholic-0/zen-bootc:testing
```

Output: `output/bootiso/install.iso`. BIB doesn't auto-pull — the target tag
must be in storage first. The ISO installs **exactly the image you pass it**:
the kickstart is role-agnostic — `%post` reads the freshly installed system's
own origin ref and re-pulls that same tag, so build from `:testing`, `:stable`
or `:dev` with zero config edits.

## Install

Boot → interactive Anaconda (locale, keyboard, timezone, partitioning, user).
`%post`: derive the tracked tag from the install's origin (`container-image
-reference=...` in `/ostree/deploy/default/deploy/*.origin`), `bootc switch`
to it (network required), then Flathub remote-add. Alternative ISO builders
(image-builder CLI, titanoboa) were rejected — history in
`testing/compaction.md`.
