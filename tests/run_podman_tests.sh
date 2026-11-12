#!/bin/bash
# Test runner for T2 audio DSP install/uninstall across distros using podman.
#
# Usage:
#   ./tests/run_podman_tests.sh           # build images + run install+uninstall tests
#   ./tests/run_podman_tests.sh --build-only
#   ./tests/run_podman_tests.sh --distro ubuntu
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

DISTRO="all"
BUILD_ONLY=false

while [ $# -gt 0 ]; do
  case "$1" in
    --build-only)
      BUILD_ONLY=true
      shift
      ;;
    --distro)
      DISTRO="$2"
      shift 2
      ;;
    ubuntu|fedora|all)
      DISTRO="$1"
      shift
      ;;
    *)
      fail "Unknown argument: $1 (use ubuntu, fedora, all, --distro <name>, or --build-only)"
      ;;
  esac
done

log() { echo -e "[TEST] $*"; }
fail() { echo -e "[FAIL] $*" >&2; exit 1; }

build_image() {
  local distro="$1"
  local containerfile="tests/${distro}/Containerfile"
  local image="t2-audio-test-${distro}"

  if [ ! -f "${REPO_DIR}/${containerfile}" ]; then
    fail "Containerfile not found: ${containerfile}"
  fi

  log "Building podman image: ${image} (from ${containerfile})"
  (cd "${REPO_DIR}" && podman build -t "${image}" -f "${containerfile}" .) \
    || fail "podman build failed for ${distro}"
  log "Image built: ${image}"
}

run_install_test() {
  local distro="$1"
  local image="t2-audio-test-${distro}"
  local container_name="t2-test-install-${distro}"

  log "Running install.sh inside ${distro} container"

  # Remove any leftover container with the same name
  podman rm -f "${container_name}" >/dev/null 2>&1 || true

  # Run install.sh and verify PipeWire components in the SAME container
  # (containers are ephemeral, so install + verification must share one run)
  podman run --rm --name "${container_name}" \
    --env DEBIAN_FRONTEND=noninteractive \
    "${image}" \
    bash -c "printf '3\n' | bash install.sh && command -v pipewire >/dev/null && command -v wireplumber >/dev/null" >"/tmp/t2-test-install-${distro}.log" 2>&1

  local rc=$?
  if [ "${rc}" -ne 0 ]; then
    fail "install.sh failed (exit ${rc}) or PipeWire components missing in ${distro} container. Log: /tmp/t2-test-install-${distro}.log"
  fi

  log "install.sh test PASSED for ${distro}"
}

run_uninstall_test() {
  local distro="$1"
  local image="t2-audio-test-${distro}"

  log "Running install→uninstall→cleanup cycle inside ${distro} container"

  # Install, uninstall, and verify cleanup — all in ONE container so the
  # uninstall actually has something to remove and we can check the result.
  podman run --rm \
    --env DEBIAN_FRONTEND=noninteractive \
    "${image}" \
    bash -c "printf '3\n' | bash install.sh >/tmp/install.log 2>&1 && printf '3\ny\ny\n' | bash uninstall.sh >/tmp/uninstall.log 2>&1 && remaining=\$(ls /etc/pipewire/pipewire.conf.d/*t2* 2>/dev/null | wc -l) && [ \"\$remaining\" -eq 0 ]" >"/tmp/t2-test-uninstall-${distro}.log" 2>&1

  local rc=$?
  if [ "${rc}" -ne 0 ]; then
    fail "install→uninstall→cleanup cycle failed (exit ${rc}) in ${distro} container. Log: /tmp/t2-test-uninstall-${distro}.log"
  fi

  log "uninstall.sh test PASSED for ${distro}"
}

main() {
  log "T2 audio DSP podman test runner"
  log "Distro(s): ${DISTRO}"

  case "${DISTRO}" in
    ubuntu)
      build_image ubuntu
      if [ "${BUILD_ONLY}" = false ]; then run_install_test ubuntu; run_uninstall_test ubuntu; fi
      ;;
    fedora)
      build_image fedora
      if [ "${BUILD_ONLY}" = false ]; then run_install_test fedora; run_uninstall_test fedora; fi
      ;;
    all)
      build_image ubuntu
      build_image fedora
      if [ "${BUILD_ONLY}" = false ]; then
        run_install_test ubuntu
        run_uninstall_test ubuntu
        run_install_test fedora
        run_uninstall_test fedora
      fi
      ;;
    *)
      fail "Unknown distro: ${DISTRO} (use ubuntu, fedora, or all)"
      ;;
  esac

  log "All podman tests PASSED"
}

main "$@"
