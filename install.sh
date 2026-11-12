#!/bin/bash

# T2 Apple Audio DSP Installation Script for Arch Linux
# Installs both speaker DSP and microphone configurations
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
REPO_URL="https://github.com/lemmyg/t2-apple-audio-dsp.git"
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
  echo -e "${BLUE}=================================${NC}"
  echo -e "${BLUE}  T2 Apple Audio DSP Installer  ${NC}"
  echo -e "${BLUE}=================================${NC}"
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

check_prerequisites() {
  print_info "Checking prerequisites..."

  # Detect distribution and select package manager
  if ! detect_distro; then
    exit 1
  fi

  # Check if T2 kernel is running
  if ! command -v lsmod &>/dev/null; then
    print_info "lsmod not available; skipping T2 kernel module check (common in containers)"
  elif ! lsmod | grep -q apple; then
    print_warning "T2 kernel modules may not be loaded. Make sure you have T2 Linux kernel installed."
    if is_interactive; then
      echo "Continue anyway? (y/N)"
      read -r response
      if [[ ! "$response" =~ ^[Yy]$ ]]; then
        exit 1
      fi
    else
      print_info "Non-interactive mode; continuing without T2 kernel module check"
    fi
  fi

  # Check if git is installed
  if ! command -v git &>/dev/null; then
    print_info "Installing git..."
    $PKG_INSTALL git
  fi

  print_success "Prerequisites check completed"
}

handle_jack_conflict() {
  # jack2 conflict is an Arch-specific packaging concern
  if [ "$PKG_MANAGER" != "pacman" ]; then
    return 0
  fi

  # Check if jack2 is installed (conflicts with pipewire-jack)
  if pacman -Qi jack2 &>/dev/null; then
    print_warning "jack2 is installed and conflicts with pipewire-jack"
    print_info "For T2 MacBook Pro audio DSP, pipewire-jack is recommended"
    print_info "(provides JACK compatibility through PipeWire's emulation layer)"
    echo
    echo "pipewire-jack is required for proper T2 audio DSP functionality."
    echo "Would you like to replace jack2 with pipewire-jack? (Y/n)"
    read -r response

    if [[ "$response" =~ ^[Nn]$ ]]; then
      print_error "Cannot proceed without pipewire-jack. Installation aborted."
      print_info "If you need JACK2 for other applications, consider using a different audio setup."
      exit 1
    fi

    print_info "Removing jack2 to allow pipewire-jack installation..."
    sudo pacman -Rdd --noconfirm jack2
    print_success "jack2 removed successfully"
  fi
}

install_dependencies() {
  print_info "Installing PipeWire and audio plugin dependencies..."

  # Handle potential jack2 conflict before proceeding (Arch-specific)
  if [ "$PKG_MANAGER" = "pacman" ]; then
    handle_jack_conflict
  fi

  # Update system
  print_info "Updating system packages..."
  $PKG_UPDATE

  # Distro-specific package names (see README for the full matrix)
  case "$PKG_MANAGER" in
    pacman)
      PIPEWIRE_PKGS="pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber"
      LADSPA_LV2_PKGS="lsp-plugins-ladspa lsp-plugins-lv2 swh-plugins calf zam-plugins-ladspa ladspa lv2"
      OPTIONAL_PKGS="caps tap-plugins rev-plugins master_me-ladspa"
      ;;
    apt)
      PIPEWIRE_PKGS="pipewire pipewire-pulse pipewire-alsa wireplumber"
      LADSPA_LV2_PKGS="ladspa-sdk swh-plugins calf-plugins zam-plugins"
      OPTIONAL_PKGS="tap-plugins rev-plugins caps"
      ;;
    dnf)
      PIPEWIRE_PKGS="pipewire pipewire-pulse pipewire-alsa wireplumber"
      LADSPA_LV2_PKGS="ladspa swh-plugins calf zam-plugins lv2"
      OPTIONAL_PKGS="tap-plugins rev-plugins caps"
      ;;
  esac

  # Install PipeWire and related packages
  print_info "Installing PipeWire components..."
  $PKG_INSTALL $PIPEWIRE_PKGS

  # Install LADSPA and LV2 plugins
  print_info "Installing audio plugins..."
  $PKG_INSTALL $LADSPA_LV2_PKGS || print_warning "Some LADSPA/LV2 plugins failed to install (package names vary by distro release)"

  # Optional additional plugins
  print_info "Installing additional audio plugins..."
  $PKG_INSTALL $OPTIONAL_PKGS || print_warning "Some optional plugins failed to install (this is usually okay)"

  print_success "Dependencies installed successfully"
}

setup_environment() {
  print_info "Setting up PipeWire environment variables..."

  # Create systemd override directory
  sudo mkdir -p /etc/systemd/user/pipewire.service.d/

  # Create environment override
  sudo tee /etc/systemd/user/pipewire.service.d/override.conf >/dev/null <<'EOF'
[Service]
Environment="LADSPA_PATH=/usr/lib/ladspa"
Environment="LV2_PATH=/usr/lib/lv2"
EOF

  print_success "Environment variables configured"
}

install_speakers_dsp() {
  print_info "Installing T2 Speakers DSP configuration..."

  # Create work directory
  mkdir -p "$WORK_DIR"
  cd "$WORK_DIR"

  # Clone speakers branch
  if [ -d "$SPEAKERS_DIR" ]; then
    print_info "Updating existing speakers repository..."
    cd "$SPEAKERS_DIR"
    git fetch
    git reset --hard origin/speakers_161
  else
    print_info "Cloning speakers DSP repository..."
    git clone -b speakers_161 "$REPO_URL" "$SPEAKERS_DIR"
    cd "$SPEAKERS_DIR"
  fi

  # Run installation script
  print_info "Running speakers DSP installation..."
  if [ -f "install.sh" ]; then
    bash install.sh
    print_success "Speakers DSP configuration installed"
  else
    print_error "install.sh not found in speakers repository"
    return 1
  fi
}

install_mic_dsp() {
  print_info "Installing T2 Microphone DSP configuration..."

  cd "$WORK_DIR"

  # Clone mic branch
  if [ -d "$MIC_DIR" ]; then
    print_info "Updating existing mic repository..."
    cd "$MIC_DIR"
    git fetch
    git reset --hard origin/mic
  else
    print_info "Cloning microphone DSP repository..."
    git clone -b mic "$REPO_URL" "$MIC_DIR"
    cd "$MIC_DIR"
  fi

  # Run installation script
  print_info "Running microphone DSP installation..."
  if [ -f "install.sh" ]; then
    bash install.sh
    print_success "Microphone DSP configuration installed"
  else
    print_error "install.sh not found in mic repository"
    return 1
  fi
}

restart_services() {
  print_info "Restarting PipeWire services..."

  # systemctl --user requires a user systemd session, which is not available
  # inside containers. Skip gracefully in that case.
  if ! systemctl --user daemon-reload >/dev/null 2>&1; then
    print_warning "No user systemd session available (expected in containers); skipping PipeWire service restart"
    return 0
  fi

  # Restart PipeWire services
  if ! systemctl --user restart pipewire pipewire-pulse wireplumber; then
    print_warning "Some PipeWire services may not have restarted correctly"
  fi

  # Wait for services to start
  sleep 5

  # Check if services are running
  if systemctl --user is-active --quiet pipewire pipewire-pulse wireplumber; then
    print_success "PipeWire services restarted successfully"
  else
    print_warning "Some PipeWire services may not have started correctly"
    print_info "Check status with: systemctl --user status pipewire pipewire-pulse wireplumber"
  fi
}

set_default_audio_devices() {
  print_info "Setting default audio devices..."

  # wpctl is not available inside containers; skip device selection there.
  if ! command -v wpctl &>/dev/null; then
    print_info "wpctl not available; skipping default audio device selection"
    return 0
  fi

  # Wait for filter chains to be fully initialized
  sleep 5

  # Find DSP filter chain node IDs using wpctl
  # Set T2 DSP Speakers as default sink
  T2_SPEAKERS_ID=$(wpctl status 2>/dev/null | grep "effect_input.filter-chain-speakers" | grep -oP '\d+(?=\.)' | head -1)

  if [ -n "$T2_SPEAKERS_ID" ]; then
    wpctl set-default "$T2_SPEAKERS_ID"
    print_success "Set MacBook Pro T2 DSP Speakers as default sink (ID: $T2_SPEAKERS_ID)"
  else
    print_warning "Could not find T2 DSP Speakers filter chain"
  fi

  # Set T2 DSP Mic as default source (builtin mic)
  # Match exact name to avoid matching headset-mic
  T2_MIC_ID=$(wpctl status 2>/dev/null | grep -E "effect_output\.filter-chain-mic\s" | grep -oP '\d+(?=\.)' | head -1)

  if [ -n "$T2_MIC_ID" ]; then
    wpctl set-default "$T2_MIC_ID"
    print_success "Set MacBook Pro T2 DSP Mic as default source (ID: $T2_MIC_ID)"
  else
    print_warning "Could not find T2 DSP Mic filter chain"
  fi

  # Also check for headset mic if available
  if wpctl status | grep -q "effect_output.filter-chain-headset-mic"; then
    print_info "MacBook Pro T2 DSP HeadSetMic also available"
  fi
}

verify_installation() {
  print_info "Verifying installation..."

  echo
  print_info "=== Service Status ==="
  systemctl --user is-active pipewire pipewire-pulse wireplumber 2>/dev/null || print_info "PipeWire services status unavailable (expected in containers)"

  echo
  print_info "=== Available Audio Devices ==="
  if command -v wpctl &>/dev/null; then
    wpctl status | grep -i "t2\|dsp\|apple" || print_warning "No T2 devices found yet (may need reboot)"
  else
    print_warning "wpctl not available, using pactl fallback"
    pactl list sinks short | grep -i "t2\|dsp\|apple" || print_warning "No T2 devices found yet (may need reboot)"
  fi

  echo
  print_info "=== Default Devices ==="
  if command -v wpctl &>/dev/null; then
    wpctl status | grep "Default Configured Devices" -A 5 || print_info "No default devices configured"
  fi

  echo
  print_info "=== LADSPA Plugins ==="
  ls /usr/lib/ladspa/*.so 2>/dev/null | wc -l | xargs echo "LADSPA plugins installed:"

  echo
  print_info "=== LV2 Plugins ==="
  ls /usr/lib/lv2/*.lv2 2>/dev/null | wc -l | xargs echo "LV2 plugins installed:"

  echo
  print_info "=== Configuration Files ==="
  if ls /etc/pipewire/pipewire.conf.d/*t2* 2>/dev/null; then
    print_success "T2 configuration files installed:"
    ls -la /etc/pipewire/pipewire.conf.d/*t2* 2>/dev/null
  else
    print_warning "No T2 config files found"
  fi

  echo
  print_info "=== Apple Device Files ==="
  if ls /usr/share/pipewire/devices/apple/*.wav 2>/dev/null; then
    print_success "Apple impulse response files installed:"
    ls -la /usr/share/pipewire/devices/apple/*.wav 2>/dev/null | wc -l | xargs echo "Files count:"
  else
    print_warning "No Apple device files found"
  fi
}

show_usage_instructions() {
  print_info "=== Usage Instructions ==="
  echo
  echo "After installation:"
  echo "1. Reboot your system to ensure all changes take effect"
  echo "2. Open audio settings (pavucontrol or system settings)"
  echo "3. For speakers:"
  echo "   - Set 'Apple Audio Driver Speakers' to 100%"
  echo "   - Select 'MacBook Pro T2 DSP Speakers' as output"
  echo "   - Keep main volume around 75% maximum"
  echo "4. For microphone:"
  echo "   - Set 'Apple Audio Device Builtin Microphone' to 100%"
  echo "   - Select 'MacBook Pro T2 DSP Mic' as input (builtin)"
  echo "   - Or 'MacBook Pro T2 DSP HeadSetMic' when using headset"
  echo
  print_warning "IMPORTANT: Do not select 'Apple Audio Driver Speakers' directly"
  print_warning "as it bypasses DSP processing and may damage speakers!"
}

cleanup() {
  print_info "Cleaning up temporary files..."
  if [ -d "$WORK_DIR" ]; then
    cd "$HOME"
    # Keep the repositories for future uninstallation
    print_info "Keeping repositories in $WORK_DIR for future reference"
  fi
}

main() {
  print_header

  echo "This script will install T2 Apple Audio DSP configuration for both"
  echo "speakers and microphone on Arch Linux."
  echo
  echo "What would you like to install?"
  echo "1) Speakers DSP only"
  echo "2) Microphone DSP only"
  echo "3) Both speakers and microphone DSP (recommended)"
  echo
  read -p "Enter your choice (1-3): " choice

  case $choice in
  1)
    INSTALL_SPEAKERS=true
    INSTALL_MIC=false
    ;;
  2)
    INSTALL_SPEAKERS=false
    INSTALL_MIC=true
    ;;
  3)
    INSTALL_SPEAKERS=true
    INSTALL_MIC=true
    ;;
  *)
    print_error "Invalid choice. Exiting."
    exit 1
    ;;
  esac

  echo
  print_info "Starting installation..."
  echo

  # Run installation steps
  check_prerequisites
  install_dependencies
  setup_environment

  if $INSTALL_SPEAKERS; then
    install_speakers_dsp
  fi

  if $INSTALL_MIC; then
    install_mic_dsp
  fi

  restart_services
  set_default_audio_devices
  verify_installation
  cleanup

  echo
  print_success "Installation completed!"
  show_usage_instructions

  echo
  print_info "Installation log saved to: /tmp/t2-audio-install.log"
  print_info "For uninstallation, use the uninstall.sh scripts in:"
  print_info "  - $SPEAKERS_DIR"
  print_info "  - $MIC_DIR"
}

# Create log file
exec > >(tee -a /tmp/t2-audio-install.log)
exec 2>&1

# Run main function
main "$@"
