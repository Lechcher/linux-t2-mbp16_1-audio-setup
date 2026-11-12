# Design

## Context

The project's install/uninstall scripts (`install.sh`, `uninstall.sh`) are Arch Linux-specific: they detect Arch via `pacman`, install packages with `pacman`, restart services with `systemctl --user`, and assume Arch package names and paths (e.g. `/usr/lib/ladspa`, `/usr/lib/lv2`, `/etc/systemd/user/`). There are no existing specs in `openspec/specs/` — this change introduces two new capabilities (`multi-distro-packages`, `podman-image-testing`) whose requirements are defined in the two spec files. See proposal.md for motivation.

## Goals / Non-Goals

**Goals:**
- Make `install.sh` and `uninstall.sh` distribution-aware: detect the distro, select `pacman`/`apt`/`dnf`, and resolve correct package names per distro
- Keep the same user-facing flow (interactive install choice, service restart, verification) across all supported distros
- Add podman-based container tests using official Ubuntu/Debian and Fedora OS images to validate scripts without physical T2 hardware per distro

**Non-Goals:**
- Provisioning T2 kernel modules or Apple audio drivers (remains a per-distro user prerequisite, documented)
- Supporting non-Linux operating systems or non-Debian/RPM-based distributions in this change
- Converting the scripts to a different language or configuration-management tool

## Decisions

**1. Keep the existing bash scripts, add distro detection at the top**
- Rationale: minimal change to the proven Arch flow; avoids a rewrite; keeps uninstall symmetry
- Alternative considered: separate per-distro script files — rejected because it duplicates the shared DSP logic and complicates maintenance

**2. Native package managers per distro: `pacman` (Arch), `apt` (Ubuntu/Debian), `dnf` (Fedora)**
- Rationale: each distro's native tool is the idiomatic, best-supported choice; avoids adding a cross-distro package manager dependency
- Alternative considered: a single package-manager abstraction layer — rejected as over-engineering for three distros

**3. PipeWire remains the audio backend on all distros**
- Rationale: PipeWire is available in Ubuntu/Debian and Fedora repos and matches the existing Arch design
- Alternative considered: PulseAudio on Ubuntu/Debian — rejected because the T2 DSP filter chains are PipeWire-native

**4. systemd `--user` for PipeWire service management on all distros**
- Rationale: Ubuntu/Debian and Fedora all use systemd; `systemctl --user daemon-reload`/`restart` works identically
- Alternative considered: distro-specific service commands — rejected as unnecessary complexity

**5. podman for container testing (not Docker)**
- Rationale: the user explicitly uses podman; podman is daemonless and rootless-friendly, matching the testing constraint
- Alternative considered: Docker — rejected because the user stated they use podman

## Risks / Trade-offs

- [Package name drift] Distro package names for LADSPA/LV2 plugins change between releases → Mitigation: document package names per distro in README and allow the user to override via environment variables
- [T2 kernel modules not provisioned] Scripts install userspace audio config but cannot load T2 kernel modules inside containers or on bare metal without the right kernel → Mitigation: keep the existing "ensure T2 modules loaded" prerequisite check and warning, unchanged from Arch behavior
- [Container testing cannot verify real audio hardware] podman containers exercise package installation and script flow, not actual speaker/mic DSP output → Mitigation: treat container tests as a regression gate for install/uninstall correctness; real-device verification remains a manual step on T2 hardware

## Migration Plan

- Add distro detection and package maps to `install.sh` and `uninstall.sh` behind a feature guard so existing Arch users see no behavior change
- Add a `tests/` directory with podman container definitions (Dockerfiles/Containerfiles) for Ubuntu/Debian and Fedora that mount the repo and run install/uninstall
- Update README.md with a supported-distribution matrix and container-testing instructions
- Rollback: revert `install.sh`/`uninstall.sh` and remove `tests/` — no persistent system state is changed by adding test definitions
