# Manufacturing Toolchain Container

This repository keeps the manufacturing toolchain in a version-pinned Docker image instead of installing Bambu Studio ad hoc on the runner.

## Why containerize the toolchain?

The manufacturing pipeline depends on a specific combination of:

- Ubuntu Linux
- OpenSCAD
- Python 3
- Bambu Studio Linux AppImage runtime
- repository-managed manufacturing profiles

Installing the slicer ad hoc on the runner leads to non-deterministic behavior because the runner environment varies, the Linux distribution path differs, and user-space configuration can affect tool startup. A versioned image keeps the build reproducible and reviewable.

## What is inside the image?

- Ubuntu 24.04 base image
- OpenSCAD CLI
- Python 3
- Bambu Studio Linux AppImage extracted into a runtime bundle
- required Linux system libraries for GUI and headless slicing

## Build the image locally

```bash
docker build -t hardware-devops-toolchain:bambu-studio toolchain/
```

## Run the canonical build in the container

```bash
docker run --rm \
  -v "$PWD:/workspace" \
  -w /workspace \
  hardware-devops-toolchain:bambu-studio \
  bash scripts/build-model.sh
```

## What the image validates

During image build, the container verifies:

```bash
openscad --version
bambu-studio --help
```

It also fails the image build if the expected AppImage CLI options are missing:

```bash
--slice
--outputdir
```

## Relationship to GitHub Actions

GitHub Actions is intentionally kept simple. It does not install Bambu Studio on the runner itself. Instead, it builds the pinned toolchain image and runs the canonical build script inside that container.

This gives the repository a stable manufacturing execution environment while preserving the canonical build path in:

```bash
scripts/build-model.sh
```

## GHCR registry usage

The repository can publish the pinned Linux toolchain image to GHCR so the canonical build path remains reproducible and decoupled from host-specific system state.

This toolchain is intentionally built for `linux/amd64`. Apple Silicon macOS systems default to `arm64`, which can create a mismatched container image for the Bambu Studio runtime. The supported build path is therefore:

```bash
docker buildx build --platform linux/amd64 --load -t hardware-devops-toolchain:bambu-studio toolchain/
```

The container image is built in Docker or CI and validated before the canonical model build runs inside the same Linux environment. This keeps the manufacturing pipeline deterministic and prevents host-native build drift.
