# Manufacturing as Code PoC: GitHub Copilot display stand

## Overview

This repository is a Manufacturing as Code experiment for a small 3D-printed hardware artifact. The design source is written in OpenSCAD, versioned in Git, and generated through an automation pipeline that produces printable and reviewable outputs.

The current implementation is a compact display stand for a GitHub Copilot figurine. The project intentionally treats the model as a software artifact: source changes are reviewed in Git, rendered into STL, previewed as PNG, sliced through a Linux toolchain, and summarized into a manufacturing report.

## Design philosophy

- Represent the geometry as source code in OpenSCAD.
- Use named variables for key dimensions instead of unexplained constants.
- Keep the model modular through OpenSCAD modules and parameter groups.
- Keep generated manufacturing artifacts distinct from source models.
- Prefer reproducible and reviewable workflows over visually decorative complexity.

## Repository structure

```text
HardwareDevOps/
├── README.md
├── AGENTS.md
├── LICENSE
├── src/
│   └── copilot-stand.scad
├── scripts/
│   ├── build-model.sh
│   ├── generate-manufacturing-report.py
│   ├── validate-stand.py
│   └── ...
├── toolchain/
│   └── Dockerfile
├── profiles/
│   ├── machine/
│   ├── process/
│   └── filament/
├── tests/
│   └── test_manufacturing_report.py
├── artifacts/
│   └── generated build outputs
├── reports/
│   └── generated manufacturing reports
├── docs/
│   ├── requirements.md
│   └── design-decisions.md
└── .github/
    └── workflows/
        └── build-model.yml
```

## Current build pipeline

This repository uses a pinned Linux toolchain image instead of depending on a host-specific installation of Bambu Studio or OpenSCAD. The design intentionally targets a reproducible Linux environment.

### Why Linux is required

The manufacturing pipeline is intentionally Linux-only. The build script fails fast on non-Linux hosts rather than silently depending on local OS-specific packaging or app bundles.

This avoids drift between:

- developer machines
- macOS host behavior
- Linux-only slicer runtime requirements
- Bambu Studio AppImage layout and library expectations

### Canonical local execution

The repository is designed to run under Docker with an explicit `linux/amd64` target. This keeps the slicer runtime consistent and avoids host mismatches that can appear on Apple Silicon machines.

```bash
docker buildx build --platform linux/amd64 --load -t hardware-devops-toolchain:bambu-studio toolchain/

docker run --rm --platform linux/amd64 \
  -v "$PWD:/workspace" \
  -w /workspace \
  hardware-devops-toolchain:bambu-studio \
  bash scripts/build-model.sh
```

The canonical build script performs the following in the container:

1. verifies the environment is Linux
2. checks for required OpenSCAD and Bambu CLI availability
3. validates the repository-managed Bambu profile directories
4. renders the STL from the OpenSCAD source
5. renders a PNG preview image
6. runs headless Bambu slicing against the STL
7. locates the generated G-code or 3MF output
8. produces a manufacturing summary report from the slicer output

## What the repository validates

The current workflow is intended to prove the following:

- the source model renders successfully in OpenSCAD
- the generated STL is consistent with the design parameters
- the PNG preview is generated
- the Bambu Studio CLI can execute in a headless Linux environment
- final slicer output is available for downstream manufacturing review
- the manufacturing report is generated from real output metadata

This is a manufacturing validation workflow, not a claim that the artifact is universally safe or physically validated across every printer, material, or use case.

## Repository-managed manufacturing contract

The current repo contains a managed profile contract under:

- `profiles/machine/`
- `profiles/process/`
- `profiles/filament/`

These directories participate in the build validation and help ensure the Bambu slicing path is operating against a known configuration instead of an implicit host-default profile.

## GitHub Actions

The workflow in `.github/workflows/build-model.yml` is designed to mirror the proven Docker-based local flow. It builds the pinned Linux toolchain image, validates the toolchain contract, and then runs the same canonical model build script in a containerized environment.

This is intentionally structured to keep the workflow close to the working local implementation rather than mixing host-dependent installs into the CI job.

## Local validation status

The repository has proven the local Linux/Docker workflow in practice:

- OpenSCAD source renders successfully
- STL is generated
- PNG preview is generated
- Bambu CLI can operate in headless mode
- real slicer metadata is parsed into a manufacturing report

The current requirement is to keep the local Docker E2E flow stable and reproducible before broadening the CI footprint.

## Known limitations and open questions

The project still documents areas that have not been physically or manufacturing-validated yet, including:

- figurine footprint and mass tolerance
- printer-specific wall thickness requirements
- infill and orientation assumptions
- tolerance needs for future accessory or fastener modules

These are treated as real engineering questions to be addressed by future validation, not as guessed assumptions.

## Future directions

The next useful steps for this project are intentionally incremental:

- add stronger automated geometry checks
- add printer- and material-specific manufacturing constraints
- add automatic clearance and tolerance validation
- expand report fields for release and review metadata
- add richer artifact review for pull requests and design diffs

## How to use this repository

1. Clone the repository.
2. Build the pinned Linux toolchain image:

```bash
docker buildx build --platform linux/amd64 --load -t hardware-devops-toolchain:bambu-studio toolchain/
```

3. Run the canonical build script inside the container:

```bash
docker run --rm --platform linux/amd64 \
  -v "$PWD:/workspace" \
  -w /workspace \
  hardware-devops-toolchain:bambu-studio \
  bash scripts/build-model.sh
```

4. Review the generated artifacts in `artifacts/` and the report in `reports/`.

5. Adjust model dimensions by setting environment variables before the build, for example:

```bash
STAND_WIDTH=100 STAND_DEPTH=80 STAND_HEIGHT=52 ./scripts/build-model.sh
```

This repository is intentionally small, but it establishes the core loop of design, validation, generation, artifact retention, and manufacturing reporting for a hardware PoC.

