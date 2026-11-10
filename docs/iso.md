# Installer ISO

Manual-dispatch CI builds a bootable network-installer ISO and publishes it to
SourceForge. Config: `disk_config/iso-kde.toml`.

## CI

```bash
gh workflow run iso-publish.yaml --ref main                 # role=testing
gh workflow run iso-publish.yaml --ref main -f role=stable  # role=stable
```

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
must be in storage first. For a `:stable` ISO, sed `zen-bootc:testing` in the
toml first.

## Install

Boot → interactive Anaconda (locale, keyboard, timezone, partitioning, user).
`%post`: `bootc switch` to the role tag (network required), then Flathub
remote-add. Alternative ISO builders (image-builder CLI, titanoboa) were
rejected — history in `testing/compaction.md`.
