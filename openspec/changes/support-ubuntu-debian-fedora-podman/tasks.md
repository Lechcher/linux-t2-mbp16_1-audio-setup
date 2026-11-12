# Tasks

## 1. Multi-distro package support

- [x] 1.1 Add distro detection to `install.sh` and `uninstall.sh` that selects `pacman` (Arch), `apt` (Ubuntu/Debian), or `dnf` (Fedora), and verify the script prints the detected distro and package manager on each supported distro
- [x] 1.2 Add Ubuntu/Debian `apt` package names for PipeWire, LADSPA, LV2, and audio plugins to `install.sh`, and verify the package list resolves with `apt-cache` / `apt-get --dry-run install`
- [x] 1.3 Add Fedora `dnf` package names for PipeWire, LADSPA, LV2, and audio plugins to `install.sh`, and verify the package list resolves with `dnf repoquery` / `dnf install --assumeno`
- [x] 1.4 Wire distro-aware dependency installation and `systemctl --user` PipeWire restart into `install.sh`, and verify services restart after install on each supported distro
- [x] 1.5 Wire distro-aware package removal and cleanup into `uninstall.sh`, and verify T2 config files and packages are removed on each supported distro

## 2. Podman container testing

- [x] 2.1 Add a Containerfile for an Ubuntu/Debian test image that installs build dependencies and copies the repo, and verify `podman build` succeeds
- [x] 2.2 Add a Containerfile for a Fedora test image that installs build dependencies and copies the repo, and verify `podman build` succeeds
- [x] 2.3 Add a test runner that starts each distro container, runs `install.sh` inside it, and verifies the script exits zero and PipeWire packages are installed
- [x] 2.4 Add a test runner that runs `uninstall.sh` inside each distro container after install, and verifies the script exits zero and T2 config files/packages are removed

## 3. Documentation and final verification

- [x] 3.1 Update `README.md` with a supported-distribution matrix and podman container-testing instructions, and verify each documented command runs as written
- [x] 3.2 Run the full install→uninstall cycle end-to-end in each distro container and verify the system is left clean with no leftover T2 configuration
