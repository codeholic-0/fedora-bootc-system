# Installer ISO — manual CI build + SourceForge publication

ISOs are **built on demand in CI** (manual dispatch) and published to
SourceForge on green. Manual/local builds remain available for dev loops.

## CI flow (primary)

Job `build-iso` in **`.github/workflows/iso-publish.yaml`** — its own file to
keep the image workflow scannable. `workflow_dispatch` only:

```bash
gh workflow run iso-publish.yaml --ref main                 # role=testing default
gh workflow run iso-publish.yaml --ref main -f role=stable  # ISO of :stable
```

1. **Cosign-verify the selected tag before building** — refuses an installer
   for an image our key didn't sign.
2. Generate the per-role kickstart (the `bootc switch` target in
   `disk_config/iso-kde.toml` is `sed`'d to `zen-bootc:<role>`), then build
   with the pinned, legacy `bootc-image-builder` (`--type anaconda-iso`).
   The target image must be pulled into runner storage first (newer BIB
   doesn't auto-pull).
3. Provenance rename + `sha256sums.txt`, 3-day artifact.
4. SourceForge rsync with **pinned host-key fingerprints** (from
   `sourceforge.net/p/forge/documentation/SSH%20Key%20Fingerprints/`, verified
   against live keyscan — not TOFU).
5. Publication self-check: ssh-verify the file exists on `frs`, then post
   the public URL to the run summary.

Public URL of the latest ISO follows
`https://sourceforge.net/projects/fedora-bootc-system/files/<YYYY-MM-DD>/zen-bootc-<role>-<YYYYMMDD>-<sha7>.iso/download`
(sourceforge.net/projects/fedora-bootc-system)

Secrets required: `SF_SSH_PRIVATE_KEY` (the key registered on SourceForge)
and `SF_USERNAME` (SourceForge account name — rsync identifies as
`$SF_USERNAME@frs.sourceforge.net`).

### One-time SourceForge web-UI steps (not automatable via frs)
- First upload creates `/home/frs/project/fedora-bootc-system/<date>/`.
- Set the default-download link for the project landing page manually if
  desired (Files → gear icon → properties).
- Auto-mirroring is on by default; leave it.

## Local build (dev loop)

```
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

The ISO installs the kickstart's bootc-switch target (`:testing`); for a
`:stable` local ISO, sed the `zen-bootc:testing` line in the toml first
(CI does this per role; BIB reads plain TOML, and the target must already
be pulled into storage — BIB doesn't auto-pull).

Output: `output/bootiso/install.iso`. Watch `df -h /tmp` in a second
terminal while it runs (osbuild stages under /tmp).

## Install experience

Boot → interactive Anaconda (locale, keyboard, timezone, partitioning, user
creation — all in the UI). The kickstart contract (`disk_config/iso-kde.toml`):

- Restores the installer screens Anaconda hides in image-mode (Storage,
  Network, Security, Services, Users, Timezone, **Localization** — without
  the Localization module the locale screens don't appear at all).
- `%post`: `bootc switch` pulls `:testing` from GHCR (needs network), then
  `flatpak remote-add flathub` — flathub setup is ISO-scoped here, not in
  the image (Containerfile-baked remote-add proved unreliable).

## PARKED — image-builder CLI path (`bootc-generic-iso`) — broken as of 2026-11-10

The new-tool flow was attempted and abandoned (full attempt in
`testing/compaction.md`):

- `image-builder list` is distro-centric — no bootc types appear (expected);
  type name validated via `image-builder manifest … bootc-generic-iso`.
- The 3 GB ISO built fine but failed in VM: boot died pre-tty under our
  SELinux-enforcing base (`selinux=0` at GRUB got past it), then still no
  Anaconda GUI — completed boot, no installer, reboot to blank. Suspect:
  installer env derived from a KDE/wayland-only base lacks the X stack
  Anaconda needs. The legacy BIB path builds its installer env from stock
  packages, which is why it doesn't hit this.

Related research: bluefin ISOs come from a dedicated repo
(`projectbluefin/iso`) using **Titanoboa** (`ublue-os/titanoboa`) — a
live-ISO-of-the-image contract (offline, `iso.yaml` inside the OS image,
features a nomodeset fallback GRUB entry). Different contract — not suitable
here (no live env wanted).
