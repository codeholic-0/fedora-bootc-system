# Installer ISO — automated weekly build + SourceForge publication

The testing ISO is **built automatically in CI** every week after the Saturday
image rebuild, and **published to SourceForge** on green. Manual/local builds
remain available for quick dev loops.

## CI flow (primary)

Job `build-iso` in **`.github/workflows/iso-publish.yaml`** — its own file to
keep the image workflow scannable, and **manual trigger only**
(`workflow_dispatch`). Deliberately not chained to the image workflow: a
`workflow_run` chain would fire on *every* main-branch image run — including
targeted minimal/final dispatch builds — producing ISOs nobody asked for.
Run it when you deliberately want a fresh ISO; it cosign-verifies the current
`:testing` tag first, so a manual build is always against the last published
image.

1. Gate (first step — schedule / `disk_config/iso-kde.toml` changes /
   dispatch `iso:` toggle).
2. **Cosign-verify `:testing` before building** — refuses to publish an
   installer for an image our key didn't sign.
3. Build with the legacy `bootc-image-builder` container
   (`--type anaconda-iso`), using `disk_config/iso-kde.toml`.
4. Provenance rename + `sha256sums.txt`, 3-day artifact.
5. SourceForge rsync with **pinned host-key fingerprints** (from
   `sourceforge.net/p/forge/documentation/SSH%20Key%20Fingerprints/`, verified
   against live keyscan — not TOFU).
6. Publication self-check: ssh-verify the file exists on `frs`, then post
   the public URL to the run summary.

Public URL of the latest ISO follows
`https://sourceforge.net/projects/fedora-bootc-system/files/<YYYY-MM-DD>/zen-bootc-testing-<YYYYMMDD>-<sha7>.iso/download`
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
mkdir -p output
sudo podman run --rm -it --privileged \
  -v "$(pwd)/output:/output" \
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  -v "$(pwd)/disk_config/iso-kde.toml:/config.toml:ro" \
  quay.io/centos-bootc/bootc-image-builder:latest \
  --rootfs ext4 --type anaconda-iso \
  ghcr.io/codeholic-0/zen-bootc:testing
```

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
