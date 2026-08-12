# Requirements for the display stand PoC

## Goal

Create a simple, parametric display stand for a GitHub Copilot figurine using OpenSCAD and Git-based workflow management. The goal is not to build a complex sculpture; it is to establish a reproducible process for design, build, preview, and artifact storage.

## Functional requirements

1. The model must be a standalone stand that supports a figurine on top.
2. The stand must be defined in OpenSCAD source code rather than generated manually from STL.
3. Major dimensions such as width, depth, height, and plate thickness must be represented as named variables.
4. A name plate area must be provided for future labeling or engraving.
5. The structure must leave room for future additions such as mounting holes, magnet pockets, or modular inserts.
6. The source model must be easy to review in a Git commit.

## Non-goals for this PoC

- No attempt to reproduce the official GitHub Copilot 3D model itself.
- No decorative or highly sculpted geometry beyond a simple support pedestal.
- No automatic manufacturing validation beyond model generation and preview output.

## Expected outputs

- STL file generated from the OpenSCAD source.
- PNG preview generated from the OpenSCAD source.
- CI workflow that builds and stores the artifacts.

## Future refinement candidates

- Add actual screw hole geometry, aligned to a known mounting standard.
- Add a profile for a specific figurine footprint and weight estimate.
- Validate minimum wall thickness and print orientation for a target printer.
- Add tolerance checks for a friction-fit or snap-fit insert.
