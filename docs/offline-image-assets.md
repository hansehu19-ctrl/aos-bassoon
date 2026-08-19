# AOS Offline Ubuntu Image Asset Preparation

This document captures the one-time online preparation flow for AOS Ubuntu 22.04 LTS cloud image assets. The resulting `/AOS/images` tree is designed to support later image customization in an offline environment.

## Directory layout

```text
/AOS/images/
├── base/
│   └── ubuntu-22.04-server-cloudimg-amd64.qcow2
├── templates/
└── offline-packages/
    ├── *.whl
    └── simple/
```

## Automated preparation

Run the repository script from any working directory:

```bash
scripts/prepare_offline_ubuntu_image_assets.sh
```

The script performs these actions:

1. Creates `/AOS/images/base`, `/AOS/images/templates`, and `/AOS/images/offline-packages`.
2. Downloads the Ubuntu 22.04 LTS server cloud image to `/AOS/images/base/ubuntu-22.04-server-cloudimg-amd64.qcow2` if it is not already present.
3. Downloads Linux x86_64 Python 3.10 binary wheels for `numpy`, `pandas`, `torch`, `onnxruntime`, and `hashdeep` into `/AOS/images/offline-packages`.
4. Installs `pip2pi` when `dir2pi` is missing.
5. Builds a local PyPI-style `simple/` index for use by offline `pip install` commands inside image customization tools such as `virt-customize`.

## Configuration

The script supports these environment overrides:

| Variable | Default | Purpose |
| --- | --- | --- |
| `AOS_IMAGES_DIR` | `/AOS/images` | Root output directory for image assets. |
| `CLOUD_IMAGE_URL` | Ubuntu 22.04 release cloud image URL | Source URL for the base qcow2 image. |
| `PYTHON_VERSION` | `310` | Python ABI target passed to `pip download`. |
| `PIP_PLATFORM` | `manylinux2014_x86_64` | Wheel platform target passed to `pip download`. |

Example:

```bash
AOS_IMAGES_DIR=/tmp/aos-images scripts/prepare_offline_ubuntu_image_assets.sh
```

## Offline usage note

Only run this preparation while external network access is intentionally available. Once the qcow2 image, wheel files, and local package index have been generated, copy or mount `/AOS/images` into the offline build host and point `pip` at the local `offline-packages/simple` index.
