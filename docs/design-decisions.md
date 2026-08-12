# Design decisions

## 1. Why a simple pedestal instead of a full enclosure?

This is the first Manufacturing as Code PoC. The objective is to establish the workflow rather than optimize the CAD geometry. A compact pedestal is sufficient to prove that a source model can be parameterized, rendered, and validated through GitHub automation.

## 2. Why are dimensions parameterized?

The stand dimensions are exposed as named variables so changes remain easy to review in Git. The design remains understandable to future engineers and avoids the hidden behavior common in hard-coded CAD files.

## 3. Why is the structure intentionally minimal?

The current design keeps the base, pedestal, top plate, and name plate area as separate blocks. That is enough to represent the stand clearly while preserving simple extension points for future add-ons.

## 4. Why reserve a mounting zone instead of adding final fastener geometry?

The repository intentionally does not guess the exact mounting pattern for a future accessory or custom fixture. A reserved mounting zone is a neutral extension point that can be refined later once actual requirements are known.

## 5. Why is the name plate area simple?

A shallow plate region is enough to reserve label space without requiring a complicated engraving toolpath or surface treatment. This keeps the first PoC focused on build reproducibility.

## Known unknowns

- Exact figurine footprint and mass have not yet been validated.
- No printer-specific wall thickness or infill assumptions are committed yet.
- No material-specific shrinkage or thermal behavior has been tested.
- No full printability validation has been automated.

## Improvement candidates

- Add a dedicated mounting-hole module with dimensions from a known fixture standard.
- Add a configurable figurine footprint parameter and a corresponding fit check.
- Add a printability profile with min wall thickness and clearance checks.
- Expand the CI pipeline to run a lightweight geometry sanity check script.
