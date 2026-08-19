#!/usr/bin/env bash
# Prepare AOS offline Ubuntu 22.04 image assets.
#
# This script intentionally keeps the externally networked steps explicit:
#   1. Download the Ubuntu 22.04 LTS cloud image once.
#   2. Download Python wheels for later offline installation.
# After these assets exist under /AOS/images, downstream image customization can run offline.

set -euo pipefail

AOS_IMAGES_DIR="${AOS_IMAGES_DIR:-/AOS/images}"
BASE_DIR="$AOS_IMAGES_DIR/base"
TEMPLATES_DIR="$AOS_IMAGES_DIR/templates"
OFFLINE_PACKAGES_DIR="$AOS_IMAGES_DIR/offline-packages"
CLOUD_IMAGE="$BASE_DIR/ubuntu-22.04-server-cloudimg-amd64.qcow2"
CLOUD_IMAGE_URL="${CLOUD_IMAGE_URL:-https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.qcow2}"
PYTHON_VERSION="${PYTHON_VERSION:-310}"
PIP_PLATFORM="${PIP_PLATFORM:-manylinux2014_x86_64}"
DEFAULT_PIP_PACKAGES=(numpy pandas torch onnxruntime hashdeep)
# Optional override: set PIP_PACKAGES to a whitespace-separated package list.
read -r -a REQUESTED_PIP_PACKAGES <<< "${PIP_PACKAGES:-${DEFAULT_PIP_PACKAGES[*]}}"

require_command() {
    local command_name="$1"
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "ERROR: required command not found: $command_name" >&2
        exit 1
    fi
}

main() {
    require_command wget
    require_command pip3

    mkdir -p "$BASE_DIR" "$TEMPLATES_DIR" "$OFFLINE_PACKAGES_DIR"

    if [[ -s "$CLOUD_IMAGE" ]]; then
        echo "Cloud image already exists, skipping download: $CLOUD_IMAGE"
    else
        wget -O "$CLOUD_IMAGE" "$CLOUD_IMAGE_URL"
    fi

    pip3 download \
        --platform "$PIP_PLATFORM" \
        --python-version "$PYTHON_VERSION" \
        --only-binary=:all: \
        "${REQUESTED_PIP_PACKAGES[@]}" \
        -d "$OFFLINE_PACKAGES_DIR/"

    mkdir -p "$OFFLINE_PACKAGES_DIR/simple"

    if ! command -v dir2pi >/dev/null 2>&1; then
        pip3 install pip2pi
    fi

    dir2pi "$OFFLINE_PACKAGES_DIR/"

    echo "Offline image assets prepared under: $AOS_IMAGES_DIR"
}

main "$@"
