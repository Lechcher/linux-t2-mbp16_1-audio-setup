#!/bin/bash

# T2 Apple Audio DSP Uninstallation Script for Arch Linux
# Removes both speaker DSP and microphone configurations
# Author: Assistant
# Version: 1.0

set -e # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
WORK_DIR="$HOME/t2-audio-setup"
SPEAKERS_DIR="$WORK_DIR/t2-speakers"
MIC_DIR="$WORK_DIR/t2-mic"

# Distro detection / package manager
DISTRO_ID=""
DISTRO_ID_LIKE=""
PKG_MANAGER=""
PKG_INSTALL=""
PKG_REMOVE=""
PKG_UPDATE=""

detect_distro() {
  if [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    DISTRO_ID="${ID}"
    DISTRO_ID_LIKE="${ID_LIKE}"
  fi

  case "$DISTRO_ID" in
    arch)
      PKG_MANAGER="pacman"
      PKG_INSTALL="sudo pacman -S --needed --noconfirm"
      PKG_REMOVE="sudo pacman -R --noconfirm"
      PKG_UPDATE="sudo pacman -Syu --noconfirm"
      ;;
    ubuntu|debian|linuxmint|pop|neon)
      PKG_MANAGER="apt"
      PKG_INSTALL="sudo apt-get install -y"
      PKG_REMOVE="sudo apt-get remove -y"
      PKG_UPDATE="sudo apt-get update"
      ;;
    fedora)
      PKG_MANAGER="dnf"
      PKG_INSTALL="sudo dnf install -y"
      PKG_REMOVE="sudo dnf remove -y"
      PKG_UPDATE="sudo dnf upgrade -y"
      ;;
    *)
      if [ -n "$DISTRO_ID_LIKE" ]; then
        case "$DISTRO_ID_LIKE" in
          *debian*)
            PKG_MANAGER="apt"
            PKG_INSTALL="sudo apt-get install -y"
            PKG_REMOVE="sudo apt-get remove -y"
            PKG_UPDATE="sudo apt-get update"
            ;;
          *fedora*|*rhel*)
            PKG_MANAGER="dnf"
            PKG_INSTALL="sudo dnf install -y"
            PKG_REMOVE="sudo dnf remove -y"
            PKG_UPDATE="sudo dnf upgrade -y"
            ;;
          *arch*)
            PKG_MANAGER="pacman"
            PKG_INSTALL="sudo pacman -S --needed --noconfirm"
            PKG_REMOVE="sudo pacman -R --noconfirm"
            PKG_UPDATE="sudo pacman -Syu --noconfirm"
            ;;
        esac
      fi
      ;;
  esac

  if [ -z "$PKG_MANAGER" ]; then
    print_error "Unsupported Linux distribution: ${DISTRO_ID:-unknown}"
    print_info "Supported distributions: Arch Linux, Ubuntu/Debian, Fedora"
    return 1
  fi

  print_info "Detected distribution: ${DISTRO_ID} (package manager: ${PKG_MANAGER})"
}

# Returns 0 when running interactively (a TTY is attached to stdin).
is_interactive() {
  [ -t 0 ]
}

# Functions
print_header() {
  echo -e "${BLUE}===================================${NC}"
  echo -e "${BLUE}  T2 Apple Audio DSP Uninstaller  ${NC}"
  echo -e "${BLUE}===================================${NC}"
  echo
}

print_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

uninstall_speakers_dsp() {
  print_info "Uninstalling T2 Speakers DSP configuration..."

  if [ -d "$SPEAKERS_DIR" ] && [ -f "$SPEAKERS_DIR/uninstall.sh" ]; then
    cd "$SPEAKERS_DIR"
    bash uninstall.sh
    print_success "Speakers DSP configuration removed"
  else
    print_warning "Speakers uninstall script not found"

    # Manual cleanup
    print_info "Attempting manual cleanup of speakers config..."
    sudo rm -f /etc/pipewire/pipewire.conf.d/10-t2_speakers.conf
    sudo rm -f /etc/pipewire/pipewire.conf.d/10-t2_161_speakers.conf
    sudo rm -f /etc/pipewire/pipewire.conf.d/*speakers*.conf

    # Remove Apple device impulse response files
    if [ -d "/usr/share/pipewire/devices/apple" ]; then
      print_info "Removing Apple device impulse response files..."
      sudo rm -rf /usr/share/pipewire/devices/apple/
    fi
  fi
}

uninstall_mic_dsp() {
  print_info "Uninstalling T2 Microphone DSP configuration..."

  if [ -d "$MIC_DIR" ] && [ -f "$MIC_DIR/uninstall.sh" ]; then
    cd "$MIC_DIR"
    bash uninstall.sh
    print_success "Microphone DSP configuration removed"
  else
    print_warning "Microphone uninstall script not found"

    # Manual cleanup
    print_info "Attempting manual cleanup of microphone config..."
    sudo rm -f /etc/pipewire/pipewire.conf.d/10-t2_mic.conf
    sudo rm -f /etc/pipewire/pipewire.conf.d/10-t2_headset_mic.conf
    sudo rm -f /etc/pipewire/pipewire.conf.d/*mic*.conf
    sudo rm -f /etc/pipewire/pipewire.conf.d/*headset*.conf
  fi
}

cleanup_environment() {
  print_info "Cleaning up environment configuration..."

  # Ask user if they want to remove PipeWire environment overrides
  echo "Do you want to remove PipeWire environment variable overrides?"
  echo "This will remove LADSPA_PATH and LV2_PATH settings."
  echo "Remove environment overrides? (y/N)"
  if is_interactive; then
    read -r response
  else
    print_info "Non-interactive mode; removing environment overrides"
    response="y"
  fi

  if [[ "$response" =~ ^[Yy]$ ]]; then
    sudo rm -f /etc/systemd/user/pipewire.service.d/override.conf
    print_success "Environment overrides removed"
  else
    print_info "Environment overrides kept"
  fi
}

remove_packages() {
  print_info "Audio packages removal options..."

  echo "Do you want to remove audio plugin packages?"
  echo "WARNING: This will remove plugins that may be used by other applications!"
  echo "Remove audio plugin packages? (y/N)"
  read -r response

  if [[ "$response" =~ ^[Yy]$ ]]; then
    print_info "Removing audio plugin packages..."

    # Distro-specific package names for removal
    case "$PKG_MANAGER" in
      pacman)
        PLUGIN_PKGS="lsp-plugins-ladspa lsp-plugins-lv2 swh-plugins calf zam-plugins-ladspa caps tap-plugins rev-plugins master_me-ladspa"
        PIPEWIRE_PKGS="pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber"
        ;;
      apt)
        PLUGIN_PKGS="calf-plugins zam-plugins swh-plugins caps tap-plugins rev-plugins"
        PIPEWIRE_PKGS="pipewire pipewire-pulse pipewire-alsa wireplumber"
        ;;
      dnf)
        PLUGIN_PKGS="calf zam-plugins swh-plugins caps tap-plugins rev-plugins master-me-ladspa"
        PIPEWIRE_PKGS="pipewire pipewire-pulse pipewire-alsa wireplumber"
        ;;
    esac

    $PKG_REMOVE $PLUGIN_PKGS 2>/dev/null || print_warning "Some plugin packages may not have been installed"

    print_success "Audio plugin packages removed"
  else
    print_info "Audio plugin packages kept"
  fi

  echo
  echo "Do you want to remove PipeWire completely?"
  echo "WARNING: This will remove your entire audio system!"
  echo "Only do this if you're switching back to PulseAudio or ALSA."
  echo "Remove PipeWire? (y/N)"
  read -r response

  if [[ "$response" =~ ^[Yy]$ ]]; then
    print_warning "Removing PipeWire..."
    $PKG_REMOVE $PIPEWIRE_PKGS 2>/dev/null || print_warning "Some PipeWire packages may not have been installed"

    print_success "PipeWire removed"
    print_warning "You may need to reinstall your preferred audio system (PulseAudio/ALSA)"

    # Offer to restore jack2 if user had it before or wants it for pro audio
    echo
    echo "Would you like to install jack2 (standalone JACK audio server)?"
    echo "This is useful if you need JACK for pro audio applications."
    echo "Install jack2? (y/N)"
    read -r jack_response

    if [[ "$jack_response" =~ ^[Yy]$ ]]; then
      if [ "$PKG_MANAGER" = "pacman" ]; then
        print_info "Installing jack2..."
        $PKG_INSTALL jack2
        print_success "jack2 installed"
      else
        print_warning "jack2 restore is only supported on Arch Linux"
      fi
    fi
  else
    print_info "PipeWire kept"
  fi
}

restore_jack2() {
  # Only offer if pipewire-jack was installed but user wants jack2 back
  if pacman -Qi pipewire-jack &>/dev/null && ! pacman -Qi jack2 &>/dev/null; then
    echo
    echo "Do you want to replace pipewire-jack with standalone jack2?"
    echo "Note: This is typically only needed for specific pro audio workflows"
    echo "that require native JACK2 (e.g., MIDI transport sync)."
    echo "Replace pipewire-jack with jack2? (y/N)"
    read -r response

    if [[ "$response" =~ ^[Yy]$ ]]; then
      print_info "Removing pipewire-jack and installing jack2..."
      sudo pacman -Rdd --noconfirm pipewire-jack
      sudo pacman -S --noconfirm jack2
      print_success "Replaced pipewire-jack with jack2"
      print_warning "Note: Some PipeWire features may not work correctly with jack2"
    fi
  fi
}

restart_services() {
  print_info "Restarting PipeWire services..."

  if systemctl --user is-active --quiet pipewire; then
    # Reload systemd configuration
    systemctl --user daemon-reload

    # Restart PipeWire services
    systemctl --user restart pipewire pipewire-pulse wireplumber

    # Wait for services to start
    sleep 3

    print_success "PipeWire services restarted"
  else
    print_info "PipeWire services not running (may have been removed)"
  fi
}

cleanup_directories() {
  print_info "Cleaning up installation directories..."

  echo "Do you want to remove the T2 audio setup directories?"
  echo "This will remove: $WORK_DIR"
  echo "Remove setup directories? (y/N)"
  if is_interactive; then
    read -r response
  else
    print_info "Non-interactive mode; keeping setup directories"
    response="n"
  fi

  if [[ "$response" =~ ^[Yy]$ ]]; then
    if [ -d "$WORK_DIR" ]; then
      rm -rf "$WORK_DIR"
      print_success "Setup directories removed"
    else
      print_info "Setup directories not found"
    fi
  else
    print_info "Setup directories kept for future reference"
  fi
}

verify_removal() {
  print_info "Verifying removal..."

  echo
  print_info "=== T2 Configuration Files ==="
  if ls /etc/pipewire/pipewire.conf.d/*t2* 2>/dev/null; then
    print_warning "Some T2 configuration files may still exist:"
    ls -la /etc/pipewire/pipewire.conf.d/*t2* 2>/dev/null
  else
    print_success "No T2 configuration files found"
  fi

  echo
  print_info "=== Apple Device Files ==="
  if ls /usr/share/pipewire/devices/apple/*.wav 2>/dev/null; then
    print_warning "Apple impulse response files still exist:"
    ls -la /usr/share/pipewire/devices/apple/*.wav 2>/dev/null
  else
    print_success "No Apple device files found"
  fi

  echo
  print_info "=== PipeWire Environment Overrides ==="
  if [ -f "/etc/systemd/user/pipewire.service.d/override.conf" ]; then
    print_info "Environment overrides still exist:"
    cat /etc/systemd/user/pipewire.service.d/override.conf
  else
    print_success "No environment overrides found"
  fi

  echo
  print_info "=== PipeWire Service Status ==="
  if systemctl --user is-active --quiet pipewire; then
    systemctl --user status pipewire --no-pager -l | head -3
  else
    print_info "PipeWire service not running"
  fi

  echo
  print_info "=== Audio Devices ==="
  if command -v wpctl &>/dev/null; then
    if wpctl status | grep -i "t2\|dsp\|apple" 2>/dev/null; then
      print_warning "T2/DSP devices may still be active:"
      wpctl status | grep -i "t2\|dsp\|apple"
    else
      print_success "No T2/DSP devices found in audio output"
    fi
  elif command -v pactl &>/dev/null; then
    if pactl list sinks short 2>/dev/null | grep -i "t2\|dsp\|apple"; then
      print_warning "T2/DSP devices may still be active"
    else
      print_success "No T2/DSP devices found"
    fi
  else
    print_info "Neither wpctl nor pactl available (PipeWire may have been removed)"
  fi
}

main() {
  print_header

  # Detect distribution and select package manager
  if ! detect_distro; then
    exit 1
  fi

  echo "This script will remove T2 Apple Audio DSP configuration."
  echo
  echo "What would you like to remove?"
  echo "1) Speakers DSP only"
  echo "2) Microphone DSP only"
  echo "3) Both speakers and microphone DSP"
  echo "4) Everything including packages"
  echo "5) Cancel"
  echo
  read -p "Enter your choice (1-5): " choice

  case $choice in
  1)
    REMOVE_SPEAKERS=true
    REMOVE_MIC=false
    REMOVE_PACKAGES=false
    ;;
  2)
    REMOVE_SPEAKERS=false
    REMOVE_MIC=true
    REMOVE_PACKAGES=false
    ;;
  3)
    REMOVE_SPEAKERS=true
    REMOVE_MIC=true
    REMOVE_PACKAGES=false
    ;;
  4)
    REMOVE_SPEAKERS=true
    REMOVE_MIC=true
    REMOVE_PACKAGES=true
    ;;
  5)
    print_info "Uninstallation cancelled."
    exit 0
    ;;
  *)
    print_error "Invalid choice. Exiting."
    exit 1
    ;;
  esac

  echo
  print_warning "Are you sure you want to proceed with removal?"
  echo "This action cannot be easily undone."
  if is_interactive; then
    read -p "Continue with removal? (y/N): " confirm
  else
    print_info "Non-interactive mode; proceeding with removal"
    confirm="y"
  fi

  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    print_info "Removal cancelled."
    exit 0
  fi

  echo
  print_info "Starting removal..."
  echo

  # Run removal steps
  if $REMOVE_SPEAKERS; then
    uninstall_speakers_dsp
  fi

  if $REMOVE_MIC; then
    uninstall_mic_dsp
  fi

  cleanup_environment

  if $REMOVE_PACKAGES; then
    remove_packages
  else
    # Offer jack2 restoration even when not removing all packages
    restore_jack2
  fi

  restart_services
  cleanup_directories
  verify_removal

  echo
  print_success "Removal completed!"

  echo
  print_info "=== Next Steps ==="
  echo "1. Reboot your system to ensure all changes take effect"
  echo "2. Check audio settings to confirm T2 DSP is no longer active"

  if $REMOVE_PACKAGES; then
    echo "3. If you removed PipeWire, you may need to install an alternative audio system"
    echo "   Example: sudo pacman -S pulseaudio pulseaudio-alsa"
  fi

  echo
  print_info "Removal log saved to: /tmp/t2-audio-uninstall.log"
}

# Create log file
exec > >(tee -a /tmp/t2-audio-uninstall.log)
exec 2>&1

# Run main function
main "$@"
