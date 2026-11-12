# Spec Delta

## Purpose

Provides container-based validation of the T2 audio DSP install/uninstall scripts using podman with official OS images, so changes can be tested across Ubuntu/Debian and Fedora without physical T2 hardware for every distribution.

## ADDED Requirements

### Requirement: Podman container images are available for each supported distro

The test setup SHALL provide official podman container images for Ubuntu/Debian and Fedora to run the install/uninstall scripts in isolation.

#### Scenario: Ubuntu container image

- **WHEN** the test runner selects the Ubuntu image
- **THEN** podman pulls or builds the official Ubuntu OS image for testing

#### Scenario: Fedora container image

- **WHEN** the test runner selects the Fedora image
- **THEN** podman pulls or builds the official Fedora OS image for testing

### Requirement: Install script runs inside each distro container

The install script SHALL execute successfully inside a container for each supported distribution, installing PipeWire and audio plugins without host-specific assumptions.

#### Scenario: Install in Ubuntu container

- **WHEN** the install script runs inside an Ubuntu container
- **THEN** PipeWire and audio plugin packages install and the script exits zero

#### Scenario: Install in Fedora container

- **WHEN** the install script runs inside a Fedora container
- **THEN** PipeWire and audio plugin packages install and the script exits zero

### Requirement: Uninstall script cleans up inside each distro container

The uninstall script SHALL execute successfully inside a container for each supported distribution, removing installed configuration and packages.

#### Scenario: Uninstall in Ubuntu container

- **WHEN** the uninstall script runs inside an Ubuntu container after install
- **THEN** T2 configuration files and packages are removed and the script exits zero

#### Scenario: Uninstall in Fedora container

- **WHEN** the uninstall script runs inside a Fedora container after install
- **THEN** T2 configuration files and packages are removed and the script exits zero
