# Testing ISO — local build instructions (CI action deferred)

The installer ISO is built **locally**, not in CI (each ISO run is a ~30+
minute job and the OCI pipeline takes precedence). The kickstart is minimal
on purpose: locale/keyboard/timezone UI comes from the
`[customizations.installer.modules]` section of the config
([`disk_config/iso-kde.toml`](../disk_config/iso-kde.toml)), and the only
contract line in the kickstart is the `%post bootc switch` that installs
our `:testing` image from GHCR — **an ISO install needs network access**.

## Build

```
mkdir -p output
sudo podman run --rm -it --privileged \
  -v "$(pwd)/output:/output" \
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  -v "$(pwd)/disk_config/iso-kde.toml:/config.toml:ro" \
  quay.io/centos-bootc/bootc-image-builder:latest \
  --rootfs ext4 \
  --type anaconda-iso \
  ghcr.io/codeholic-0/zen-bootc:testing
```

Result: `output/bootiso/install.iso` (VM-testable immediately).

## Notes

- Requires the rootful podman store (`/var/lib/containers/storage`) — the
  user store will not be seen by the builder.
- If depsolve fails with "No match for argument: <base package>", confirm
  §3 of `Containerfile.testing` (`cp /usr/share/dnf5/repos.d/*.repo
  /etc/yum.repos.d/`) is present in the image being used — that bridge is
  what BIB's depsolver needs.
- Uses the legacy `bootc-image-builder` container (deprecated in favor of
  `image-builder`'s `bootc-generic-iso`) — re-evaluate when CI is wired to
  ISOs, per `testing/compaction.md`.
- Publishing to SourceForge (size-safe storage) remains on the roadmap;
  the kickstart's `bootc switch` pulls `:testing` from GHCR at install time.
