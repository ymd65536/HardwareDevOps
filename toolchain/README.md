# Manufacturing Toolchain Container

This repository keeps the manufacturing toolchain in a version-pinned Docker image instead of installing PrusaSlicer directly on the GitHub Actions runner.

## Why containerize the toolchain?

The manufacturing pipeline depends on a specific combination of:

- Ubuntu Linux
- OpenSCAD
- Python 3
- PrusaSlicer 2.9.5
- repository-managed manufacturing profiles

Installing the slicer ad hoc on the runner leads to non-deterministic behavior because the runner environment varies, the Linux distribution path differs, and user-space configuration can affect tool startup. A versioned image keeps the build reproducible and reviewable.

## What is inside the image?

- Ubuntu 24.04 base image
- OpenSCAD CLI
- Python 3
- PrusaSlicer built from the official upstream source at tag `version_2.9.5`
- required Linux system libraries for CLI execution and slicing

## Build the image locally

```bash
docker build -t hardware-devops-toolchain:prusaslicer-2.9.5 toolchain/
```

## Run the canonical build in the container

```bash
docker run --rm \
  -v "$PWD:/workspace" \
  -w /workspace \
  hardware-devops-toolchain:prusaslicer-2.9.5 \
  bash scripts/build-model.sh
```

## What the image validates

During image build, the container verifies:

```bash
prusa-slicer --version
openscad --version
prusa-slicer --help
```

It also fails the image build if the required CLI flags are missing:

```bash
--printer-profile
--print-profile
--material-profile
```

## Relationship to GitHub Actions

GitHub Actions is intentionally kept simple. It does not install PrusaSlicer on the runner itself. Instead, it builds the pinned toolchain image and runs the canonical build script inside that container.

This gives the repository a stable manufacturing execution environment while preserving the canonical build path in:

```bash
scripts/build-model.sh
```

## GHCR registry usage

The repository publishes the pinned Linux toolchain image to GHCR so the canonical build path is reproducible and decoupled from host-specific system state.

```text
ghcr.io/ymd65536/hardware-devops-toolchain:2.9.5
```

This toolchain is intentionally built for `linux/amd64`. Apple Silicon macOS systems default to `arm64`, which can create a mismatched container image for the PrusaSlicer dependency set. The supported build path is therefore:

```bash
docker buildx build --platform linux/amd64 --load -t hardware-devops-toolchain:2.9.5 toolchain/
```

The container image is built in GitHub Actions and validated before the canonical model build runs inside the same Linux environment. This keeps the manufacturing pipeline deterministic and prevents host-native build drift.
