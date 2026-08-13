#!/usr/bin/env python3
"""Validate basic manufacturing sanity checks for the display stand model."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCAD_PATH = ROOT / "src" / "copilot-stand.scad"

REQUIRED_KEYS = [
    "stand_width",
    "stand_depth",
    "stand_height",
    "base_thickness",
    "pedestal_width",
    "pedestal_depth",
    "pedestal_height",
    "top_plate_thickness",
    "nameplate_width",
    "nameplate_depth",
    "nameplate_height",
    "mounting_hole_enabled",
    "mounting_hole_diameter",
    "mounting_hole_pitch",
    "mounting_hole_margin",
    "mounting_hole_depth",
]


def read_scad_values(path: Path) -> dict[str, float | bool]:
    text = path.read_text(encoding="utf-8")
    matches = re.findall(
        r"^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(true|false|[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?)\s*;",
        text,
        re.MULTILINE,
    )
    out: dict[str, float | bool] = {}
    for name, value in matches:
        if value in {"true", "false"}:
            out[name] = value == "true"
        else:
            out[name] = float(value)
    return out


def ensure(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def main() -> int:
    values = read_scad_values(SCAD_PATH)
    missing = [key for key in REQUIRED_KEYS if key not in values]
    if missing:
        raise ValueError(f"Missing required parameter(s): {', '.join(missing)}")

    ensure(values["stand_width"] > 0, "stand_width must be positive")
    ensure(values["stand_depth"] > 0, "stand_depth must be positive")
    ensure(values["stand_height"] > 0, "stand_height must be positive")
    ensure(values["base_thickness"] > 0, "base_thickness must be positive")
    ensure(values["pedestal_width"] > 0, "pedestal_width must be positive")
    ensure(values["pedestal_depth"] > 0, "pedestal_depth must be positive")
    ensure(values["pedestal_height"] > 0, "pedestal_height must be positive")
    ensure(values["top_plate_thickness"] > 0, "top_plate_thickness must be positive")
    ensure(values["nameplate_width"] > 0, "nameplate_width must be positive")
    ensure(values["nameplate_depth"] > 0, "nameplate_depth must be positive")
    ensure(values["nameplate_height"] > 0, "nameplate_height must be positive")
    ensure(isinstance(values["mounting_hole_enabled"], bool), "mounting_hole_enabled must be a boolean")
    ensure(values["mounting_hole_diameter"] > 0, "mounting_hole_diameter must be positive")
    ensure(values["mounting_hole_pitch"] > 0, "mounting_hole_pitch must be positive")
    ensure(values["mounting_hole_margin"] > 0, "mounting_hole_margin must be positive")
    ensure(values["mounting_hole_depth"] > 0, "mounting_hole_depth must be positive")

    ensure(values["pedestal_width"] < values["stand_width"], "pedestal_width must be smaller than stand_width")
    ensure(values["pedestal_depth"] < values["stand_depth"], "pedestal_depth must be smaller than stand_depth")
    ensure(values["base_thickness"] < values["stand_height"], "base_thickness must be smaller than stand_height")
    ensure(
        abs((values["base_thickness"] + values["pedestal_height"] + values["top_plate_thickness"]) - values["stand_height"]) < 1e-6,
        "base_thickness + pedestal_height + top_plate_thickness must equal stand_height",
    )
    ensure(values["nameplate_width"] <= values["stand_width"], "nameplate_width must not exceed stand_width")
    ensure(values["nameplate_depth"] <= values["stand_depth"], "nameplate_depth must not exceed stand_depth")
    ensure(values["top_plate_thickness"] <= values["stand_height"], "top_plate_thickness must be usable within the stand height")
    ensure(values["mounting_hole_pitch"] < values["stand_width"], "mounting_hole_pitch must fit within stand_width")
    ensure(values["mounting_hole_margin"] < values["stand_depth"], "mounting_hole_margin must fit within stand_depth")

    print("Design validation passed")
    for key in REQUIRED_KEYS:
        print(f"{key}={values[key]}")
    print("Summary: stand dimensions are positive and pedestal/nameplate remain within the body footprint.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:  # pragma: no cover - CLI error path
        print(f"Validation failed: {exc}", file=sys.stderr)
        raise SystemExit(1)
