# Spec Delta

## Purpose

Enables installation of PipeWire and T2 audio DSP audio-plugin dependencies through each supported Linux distribution's native package manager, so the same install/uninstall scripts work on Arch, Ubuntu/Debian, and Fedora.

## ADDED Requirements

### Requirement: Distro detection selects the correct package manager

The installer SHALL detect the host Linux distribution and select the matching package manager and package set: `pacman` for Arch, `apt` for Ubuntu/Debian, and `dnf` for Fedora.

#### Scenario: Arch Linux uses pacman

- **WHEN** the installer runs on a system with `pacman` available
- **THEN** the installer uses `pacman` to install PipeWire and audio plugins

#### Scenario: Ubuntu/Debian uses apt

- **WHEN** the installer runs on a system with `apt` available
- **THEN** the installer uses `apt` to install PipeWire and audio plugins

#### Scenario: Fedora uses dnf

- **WHEN** the installer runs on a system with `dnf` available
- **THEN** the installer uses `dnf` to install PipeWire and audio plugins

### Requirement: Distro-specific package names resolve correctly

The installer SHALL map each audio dependency to the correct package name for the detected distribution.

#### Scenario: Ubuntu/Debian package names

- **WHEN** installing on Ubuntu/Debian
- **THEN** the installer resolves PipeWire, LADSPA, LV2, and plugin packages to their Debian/Ubuntu package names

#### Scenario: Fedora package names

- **WHEN** installing on Fedora
- **THEN** the installer resolves PipeWire, LADSPA, LV2, and plugin packages to their Fedora package names

### Requirement: Unsupported distributions are rejected with a clear error

The installer SHALL abort with a clear, actionable error message when run on a distribution it does not support.

#### Scenario: Unsupported distro

- **WHEN** the installer detects an unsupported distribution
- **THEN** the installer exits non-zero and names the supported distributions
