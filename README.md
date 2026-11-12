# MacBook Pro T2 16,1 Audio DSP Setup for Arch Linux

This repository provides automated installation and uninstallation scripts for T2 Apple Audio DSP configuration on Arch Linux systems, specifically designed for MacBook Pro 16,1 model (2019).

## Overview

The T2 chip in MacBook Pro models requires special audio processing to prevent speaker damage and provide optimal audio quality. This setup includes:

- **Speaker DSP**: Multi-band compression, bass enhancement, and speaker protection
- **Microphone DSP**: Noise reduction, compression, and gain control for both builtin and headset microphones
- **PipeWire Integration**: Native PipeWire filter chains for low-latency audio processing

## Features

-  Automated installation of T2 audio DSP configuration
-  Support for both speakers and microphones (builtin + headset)
-  Multi-band compression and speaker protection
-  Impulse response convolution for accurate speaker modeling
-  Bass enhancement and limiting
-  Microphone gain control and compression
-  Easy uninstallation with complete cleanup
-  Verification and troubleshooting tools

## Requirements

- **Hardware**: MacBook Pro 16,1 (2019) with T2 chip
- **OS**: Arch Linux, Ubuntu/Debian, or Fedora (see Supported Distributions below)
- **Audio**: PipeWire audio system
- **Kernel**: T2 Linux kernel with Apple audio drivers

## Supported Distributions

| Distribution | Package Manager | Status |
|--------------|-----------------|--------|
| Arch Linux | `pacman` | Supported (original) |
| Ubuntu 22.04/24.04 LTS | `apt` | Supported |
| Debian 12 | `apt` | Supported |
| Fedora 40/41 | `dnf` | Supported |

The install/uninstall scripts auto-detect your distribution and use the native package manager. T2 kernel module availability remains a per-distributor prerequisite — ensure the T2 kernel and Apple audio drivers are installed before running the scripts.

## Container Testing (podman)

The project includes podman-based container tests so install/uninstall can be validated across distributions without physical T2 hardware for every distro:

```bash
# Build and run the full install→uninstall test cycle for all distros
bash tests/run_podman_tests.sh

# Test a single distro
bash tests/run_podman_tests.sh --distro ubuntu
bash tests/run_podman_tests.sh --distro fedora

# Build container images only
bash tests/run_podman_tests.sh --build-only
```

Container definitions live in `tests/ubuntu/Containerfile` and `tests/fedora/Containerfile`. Container tests exercise package installation and script flow; real speaker/microphone DSP output still requires physical T2 hardware.


## Quick Start

### Installation

1. **Clone and run the installer**:
   ```bash
   git clone <this-repo>
   cd linux-t2-mbp16_1-arch-audio-setup
   chmod +x install.sh
   ./install.sh
   ```

2. **Choose installation type**:
   - Option 1: Speakers DSP only
   - Option 2: Microphone DSP only
   - Option 3: Both speakers and microphone DSP (recommended)

3. **Reboot your system** after installation

### Uninstallation

```bash
chmod +x uninstall.sh
./uninstall.sh
```

## What Gets Installed

### Configuration Files
- `/etc/pipewire/pipewire.conf.d/10-t2_161_speakers.conf` - Speaker DSP configuration
- `/etc/pipewire/pipewire.conf.d/10-t2_mic.conf` - Builtin microphone DSP
- `/etc/pipewire/pipewire.conf.d/10-t2_headset_mic.conf` - Headset microphone DSP

### Audio Device Files
- `/usr/share/pipewire/devices/apple/` - Impulse response files for accurate speaker modeling:
  - `macbook_pro_t2_16_1_tweeters_4-*.wav` (44kHz, 48kHz, 96kHz)
  - `macbook_pro_t2_16_1_woofers_4-*.wav` (44kHz, 48kHz, 96kHz)

### System Configuration
- `/etc/systemd/user/pipewire.service.d/override.conf` - Environment variables for audio plugins

### Audio Plugins Installed
- **LADSPA plugins**: `lsp-plugins-ladspa`, `swh-plugins`, `zam-plugins-ladspa`, `caps`, `tap-plugins`, `rev-plugins`
- **LV2 plugins**: `lsp-plugins-lv2`, `calf`
- **Additional**: Various audio processing plugins

## Audio Devices Created

After installation, you'll see these new audio devices:

### Speakers
- **MacBook Pro T2 DSP Speakers** - Use this as your default output device
- Provides speaker protection and enhanced audio quality

### Microphones
- **MacBook Pro T2 DSP Mic** - Builtin microphone with noise reduction and compression
- **MacBook Pro T2 DSP HeadSetMic** - Headset microphone with optimized processing

## Usage Instructions

### Setting Up Audio

1. **Open audio settings** (pavucontrol or system settings)

2. **For speakers**:
   - Set "Apple Audio Driver Speakers" to 100% in hardware controls
   - Select "MacBook Pro T2 DSP Speakers" as your default output device
   - Keep main volume around 75% maximum for optimal quality

3. **For microphone**:
   - Set "Apple Audio Device Builtin Microphone" to 100% in hardware controls
   - Select "MacBook Pro T2 DSP Mic" for builtin microphone
   - Or "MacBook Pro T2 DSP HeadSetMic" when using headset

### Important Safety Notes

� **CRITICAL**: Never select "Apple Audio Driver Speakers" directly as your output device. This bypasses the DSP processing and may damage your speakers due to lack of protection filters.

 **ALWAYS**: Use "MacBook Pro T2 DSP Speakers" which includes proper speaker protection.

## Technical Details

### Speaker DSP Chain
1. **Bass Enhancement** (Calf Bass Enhancer) - Enhances low frequencies
2. **Multi-band Compressor** (LSP Multi-band Compressor) - 4-band compression for dynamic control
3. **Limiter** (LADSPA Fast Lookahead Limiter) - Peak limiting for speaker protection
4. **Convolution** - Separate processing for tweeters and woofers using impulse responses

### Microphone DSP Chain
1. **Preamp** - Gain adjustment (15dB for headset, 35dB for builtin)
2. **Compressor** (SC4 Compressor) - Dynamic range control
3. **Limiter** - Peak limiting for clean output

### Sample Rates Supported
- 44.1 kHz, 48 kHz, 96 kHz with automatic impulse response selection

## Troubleshooting

### Check Installation Status
```bash
# Verify PipeWire services
systemctl --user status pipewire pipewire-pulse wireplumber

# Check audio devices
wpctl status

# Verify configuration files
ls -la /etc/pipewire/pipewire.conf.d/*t2*

# Check Apple device files
ls -la /usr/share/pipewire/devices/apple/
```

### Common Issues

**Audio not working after installation:**
1. Reboot your system
2. Check that T2 kernel modules are loaded: `lsmod | grep apple`
3. Verify PipeWire services are running
4. Make sure you're using the DSP devices, not the raw Apple devices

**No T2 devices visible:**
1. Ensure you have T2 Linux kernel installed
2. Check that Apple audio drivers are loaded
3. Restart PipeWire services: `systemctl --user restart pipewire pipewire-pulse wireplumber`

**Speaker protection not working:**
1. Verify you're using "MacBook Pro T2 DSP Speakers" not "Apple Audio Driver Speakers"
2. Check configuration files are properly installed
3. Ensure LADSPA/LV2 plugins are installed

### Getting Help

1. Check installation logs: `/tmp/t2-audio-install.log`
2. Check uninstallation logs: `/tmp/t2-audio-uninstall.log`
3. Verify plugin installation: `ls /usr/lib/ladspa/ /usr/lib/lv2/`

## Contributing

This setup is based on the excellent work from:
- [T2 Apple Audio DSP Project](https://github.com/lemmyg/t2-apple-audio-dsp)
- T2 Linux community

### Reporting Issues

When reporting issues, please include:
- Hardware model (MacBook Pro version)
- Kernel version: `uname -a`
- PipeWire version: `pipewire --version`
- Installation logs
- Output of `wpctl status`

## License

This project is licensed under the MIT License - see individual configuration files for specific licensing terms.

## Acknowledgments

- **T2 Linux Team** - For the original T2 audio configurations
- **lemmyg** - For the T2 Apple Audio DSP project
- **PipeWire Community** - For the excellent audio framework
- **LSP Plugins** - For the audio processing plugins
- **Calf Studio Gear** - For the bass enhancement plugin

---

**� Disclaimer**: This software modifies system audio configuration. While it includes speaker protection, use at your own risk. Always test at low volumes first and ensure you understand the configuration before use.