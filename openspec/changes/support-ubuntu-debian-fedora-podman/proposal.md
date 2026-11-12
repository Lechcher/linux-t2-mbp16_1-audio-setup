# Proposal

## Why

The T2 Apple Audio DSP setup currently only supports Arch Linux: its install and uninstall scripts hard-code `pacman` for package management and assume Arch-specific package names and paths. Users with MacBook Pro 16,1 (T2) hardware running Ubuntu/Debian or Fedora cannot use the project. This change adds native multi-distro package management so the same scripts work on Ubuntu/Debian (`apt`) and Fedora (`dnf`), and introduces podman-based container testing using official OS images so the scripts can be validated across distributions without requiring physical T2 hardware for every distro.

## What Changes

- Add distribution detection to `install.sh` and `uninstall.sh` that selects the native package manager (`pacman`, `apt`, or `dnf`) and the correct package names for each supported distro
- Add Ubuntu/Debian package lists for PipeWire, LADSPA, and LV2 audio plugins (replacing Arch `pacman` package names)
- Add Fedora package lists for PipeWire, LADSPA, and LV2 audio plugins (replacing Arch `pacman` package names)
- Add podman-based test definitions using official Ubuntu/Debian and Fedora OS images to run install/uninstall scripts in containers
- Update README.md to document supported distributions and container-based testing

## Capabilities

### New Capabilities

- `multi-distro-packages`: Distribution-agnostic installation of PipeWire and T2 audio DSP dependencies through each supported distro's native package manager (`apt` for Ubuntu/Debian, `dnf` for Fedora, `pacman` for Arch), including correct package names and service management per distro
- `podman-image-testing`: Container-based validation of the install/uninstall scripts using podman with official OS images for Ubuntu/Debian and Fedora, so changes can be tested across distributions without physical T2 hardware per distro

### Modified Capabilities

(None — no existing specs in the project; this change introduces new capability-level behavior rather than altering an existing spec's requirements.)

## Impact

- `install.sh`: package installation, dependency handling, and service restart logic become distribution-aware
- `uninstall.sh`: package removal and cleanup logic become distribution-aware
- New test artifacts (podman container definitions / OS images) under a `tests/` directory
- `README.md`: supported-distribution matrix and container testing instructions

Assumptions (minor, recorded for scope): Ubuntu/Debian targets recent LTS releases (Ubuntu 22.04/24.04 LTS, Debian 12); Fedora targets a recent release (Fedora 40/41). T2 kernel module availability remains a per-distro prerequisite documented for the user, not something this change provisions.
