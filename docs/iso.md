# Testing ISO — legacy bootc-image-builder (anaconda-iso)

The installer ISO is built **locally** in one stage. No CI action ships it.

## The command

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

Output: `output/bootiso/install.iso` (plus checksums). Copy to a USB stick or
attach to a VM CD-ROM to test.

## Install experience

Boots to a **full interactive Anaconda**: locale, keyboard, timezone/clock,
partitioning, and user creation are all chosen in the UI — nothing is baked
into the image (image stays locale-neutral by policy). The two things the
config does:

1. `disk_config/iso-kde.toml` restores the installer screens Anaconda hides in
   image-mode installs: Storage, Distribution, Users, Language, Keyboard,
   Time zone, Network. The Subscription module (RHEL-only noise) is disabled.
2. The single kickstart contract line (`%post`) swaps the installer
   environment for our published OCI: `bootc switch` pulls
   `ghcr.io/codeholic-0/zen-bootc:testing` from GHCR during install — so the
   machine **needs network access**, and the ISO itself stays lean (~3 GB).

## Watchpoints

- osbuild stages build under `/tmp` — if the host's `/tmp` is small, watch
  `df -h /tmp` in a second terminal; the documented fix when it fills is
  enlarging swap/tmp, not retrying blind.
- The `bootc-image-builder` container is now the compatibility layer of the
  merged `image-builder` multicall binary; the legacy flag surface
  (`--type`, `--config`, `--rootfs`) is kept working as a transition path.

## PARKED — new image-builder CLI path (`bootc-generic-iso`) — broken as of 2026-11-10

The new-tool flow (installer container derived FROM `:testing`, then
`image-builder-cli build … bootc-generic-iso`) was attempted and abandoned:

- Type name validated OK (`bootc-generic-iso`), a 3 GB ISO was produced, but
  it did not boot cleanly in a VM.
- Symptom 1: boot died before any console/tty under our SELinux-enforcing
  base. Adding `selinux=0` to the GRUB entry got further.
- Symptom 2: with SELinux disabled, the installer still never launched its
  GUI — boot completed, no Anaconda appeared, then reboot into a blank screen.
  Root cause unproven (suspect: derived installer env from a KDE/wayland-only
  base missing the X stack Anaconda needs; `inst.text` discriminator test was
  never run).
- Consequence: an installer environment that derives from an enforcing, wayland-only
  appliance image inherits problems the stock upstream walkthrough (derived from
  `fedora-bootc:45`, GNOME-ish, with `selinux=0` baked in) does not have.

Related architecture research (kept for reference): bluefin builds its ISOs in
a dedicated repo (`projectbluefin/iso`) using **Titanoboa**
(`ublue-os/titanoboa`) — a different contract entirely: a live ISO of the
actual OS image (offline install, embedded into `:testing` image itself via
`/usr/lib/bootc-image-builder/iso.yaml`). Not suitable for this project (no
live env wanted); do not confuse the two contracts.

## SourceForge publication (manual, no CI)

After a successful build and VM test, publish the ISO manually:

```
rsync -e "ssh -i <sf_ci_key>" <output>/bootiso/install.iso \
  <sf-user>@frs.sourceforge.net:/home/frs/project/zen-bootc/<YYYY-MM-DD>/
```

Recommended filename before upload: `zen-bootc-testing-<YYYYMMDD>-<shortsha>.iso`
to carry provenance (matching the tag scheme). Also drop a `sha256sums.txt`
next to it.
