# AGENTS.md

## Project purpose

This repository is a laboratory for exploring Manufacturing as Code and Hardware DevOps using GitHub.

The objective is not only to store 3D model files in Git.

The objective is to make physical artifact development:

* reproducible
* reviewable
* testable
* traceable
* automatable

using software engineering practices such as Git, Pull Requests, CI, automated validation, release management, and documentation as code.

The initial target is 3D printing.

Do not optimize only for visual appearance. Prefer designs and workflows that can be inspected, changed, regenerated, and validated.

## Core principle

Treat the physical artifact as the output of a development pipeline.

The intended lifecycle is:

```text
Requirement
→ Design
→ Review
→ Build
→ Validate
→ Manufacture
→ Inspect
→ Feedback
```

GitHub is the source of truth for the development process.

Manufacturing services and 3D printers are downstream manufacturing environments.

## Current scope

The first implementation uses OpenSCAD.

OpenSCAD source files are treated as source code.

Generated STL, 3MF, PNG, or other manufacturing artifacts are build outputs unless otherwise documented.

The first goal is to establish a reproducible pipeline rather than create a highly complex model.

## Design rules

When editing OpenSCAD models:

* Prefer parametric modeling
* Define important dimensions as named variables
* Avoid unexplained magic numbers
* Use modules to separate meaningful components
* Keep geometry understandable and maintainable
* Prefer simple geometry over unnecessary complexity
* Document units explicitly and use millimeters unless otherwise stated
* Keep manufacturing constraints separate from decorative choices where possible
* Do not silently change critical dimensions
* Record significant design decisions in `docs/design-decisions.md`

A model that renders successfully is not automatically considered manufacturable.

Always distinguish between:

1. syntactically valid model
2. geometrically valid model
3. manufacturable model
4. physically verified model

## Manufacturing assumptions

The current primary manufacturing process is 3D printing.

Do not assume that a geometry is printable only because OpenSCAD can generate an STL.

When relevant, consider:

* minimum wall thickness
* clearance
* fit
* hole diameter
* overhang
* support requirements
* print orientation
* dimensional tolerance
* bounding dimensions
* material constraints

If a manufacturing constraint cannot yet be automatically validated, document it instead of inventing a validation rule.

Do not present an estimated rule as a guaranteed manufacturing requirement.

## Source and generated artifacts

Prefer the following separation:

```text
src/
  source models

docs/
  requirements and design decisions

artifacts/
  generated outputs

.github/workflows/
  reproducible automation
```

Source files should be sufficient to regenerate build artifacts whenever possible.

Do not manually edit generated STL files when the change can be expressed in source.

## CI principles

GitHub Actions should gradually become the Hardware Quality Gate for this repository.

The pipeline should evolve toward:

```text
Source
→ Syntax / build validation
→ Geometry validation
→ Manufacturing rule validation
→ Preview
→ Release artifact
```

For the initial implementation:

* verify that OpenSCAD can render the source
* generate STL
* generate PNG preview
* fail the workflow when generation fails
* upload generated outputs as GitHub Actions artifacts

Keep workflows deterministic and understandable.

Do not add unnecessary dependencies or complex CI infrastructure without a concrete validation requirement.

## Testing philosophy

Manufacturing tests should represent meaningful physical constraints rather than arbitrary implementation details.

Prefer tests such as:

```text
model can be generated
bounding dimensions are within limits
minimum required dimensions are respected
expected parameters are valid
manufacturing profile constraints are satisfied
```

over tests that only check file existence.

When adding a rule, explain what manufacturing failure the rule is intended to prevent.

## Git and Pull Request philosophy

Every meaningful design change should be explainable as a change in physical behavior or manufacturing intent.

Good examples:

```text
feat: increase stand width to improve stability
fix: add clearance for printed fit
refactor: parameterize mounting hole positions
```

Avoid changes that cannot explain why the physical artifact changed.

Pull Requests should make it possible to answer:

* What changed?
* Why was it changed?
* What physical behavior is affected?
* Was the model regenerated successfully?
* Were manufacturing constraints checked?
* What still requires physical verification?

## GitHub Copilot usage

GitHub Copilot is an engineering assistant, not the authority for manufacturing correctness.

Copilot may:

* propose OpenSCAD implementations
* refactor parametric models
* create validation scripts
* create GitHub Actions workflows
* summarize design differences
* suggest manufacturing risks
* update documentation

Copilot must not claim that a design is safe, structurally sound, or manufacturable without evidence.

When uncertain:

1. identify the uncertainty
2. avoid inventing manufacturing specifications
3. document the assumption
4. propose a validation method

Prefer changing design source through a Pull Request rather than directly editing generated artifacts.

## Documentation

Documentation is part of the implementation.

`README.md` should explain how another engineer can reproduce the artifact.

`docs/requirements.md` should describe what the physical artifact must accomplish.

`docs/design-decisions.md` should record why important design choices were made.

Keep documentation synchronized with the current source and build process.

## Definition of done

A change is not complete only because the SCAD file has been edited.

For the initial phase, a change is complete when:

* source changes are understandable
* OpenSCAD generation succeeds
* STL is generated
* PNG preview is generated
* GitHub Actions succeeds
* important design decisions are documented

For later phases, the definition of done should expand to include manufacturing validation and physical inspection.

## Long-term direction

The repository should eventually explore:

* manufacturing profiles as code
* automated geometry validation
* minimum wall thickness rules
* clearance and tolerance checks
* slicer automation
* comparison of home FDM printing and external manufacturing services
* generated manufacturing reports
* release management for physical artifacts
* Hardware Quality Gates
* Manufacturing Policy as Code
* AI-assisted design review
* AI agents for design, validation, manufacturing, and feedback loops

Do not implement all of these at once.

Prefer incremental experiments with measurable results.

The guiding question for every addition is:

> Does this make physical artifact development more reproducible, reviewable, testable, traceable, or automatable?
