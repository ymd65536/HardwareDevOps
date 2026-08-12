#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

STAND_WIDTH="${STAND_WIDTH:-90}"
STAND_DEPTH="${STAND_DEPTH:-70}"
STAND_HEIGHT="${STAND_HEIGHT:-46}"
BASE_THICKNESS="${BASE_THICKNESS:-5}"
PEDESTAL_WIDTH="${PEDESTAL_WIDTH:-58}"
PEDESTAL_DEPTH="${PEDESTAL_DEPTH:-44}"
PEDESTAL_HEIGHT="${PEDESTAL_HEIGHT:-22}"
TOP_PLATE_THICKNESS="${TOP_PLATE_THICKNESS:-4}"
NAMEPLATE_WIDTH="${NAMEPLATE_WIDTH:-34}"
NAMEPLATE_DEPTH="${NAMEPLATE_DEPTH:-12}"
NAMEPLATE_HEIGHT="${NAMEPLATE_HEIGHT:-2}"
MOUNTING_HOLE_ENABLED="${MOUNTING_HOLE_ENABLED:-true}"
MOUNTING_HOLE_DIAMETER="${MOUNTING_HOLE_DIAMETER:-3.2}"
MOUNTING_HOLE_PITCH="${MOUNTING_HOLE_PITCH:-48}"
MOUNTING_HOLE_MARGIN="${MOUNTING_HOLE_MARGIN:-8}"
MOUNTING_HOLE_DEPTH="${MOUNTING_HOLE_DEPTH:-12}"

mkdir -p artifacts reports

python3 scripts/validate-stand.py

openscad \
  -D stand_width=${STAND_WIDTH} \
  -D stand_depth=${STAND_DEPTH} \
  -D stand_height=${STAND_HEIGHT} \
  -D base_thickness=${BASE_THICKNESS} \
  -D pedestal_width=${PEDESTAL_WIDTH} \
  -D pedestal_depth=${PEDESTAL_DEPTH} \
  -D pedestal_height=${PEDESTAL_HEIGHT} \
  -D top_plate_thickness=${TOP_PLATE_THICKNESS} \
  -D nameplate_width=${NAMEPLATE_WIDTH} \
  -D nameplate_depth=${NAMEPLATE_DEPTH} \
  -D nameplate_height=${NAMEPLATE_HEIGHT} \
  -D mounting_hole_enabled=${MOUNTING_HOLE_ENABLED} \
  -D mounting_hole_diameter=${MOUNTING_HOLE_DIAMETER} \
  -D mounting_hole_pitch=${MOUNTING_HOLE_PITCH} \
  -D mounting_hole_margin=${MOUNTING_HOLE_MARGIN} \
  -D mounting_hole_depth=${MOUNTING_HOLE_DEPTH} \
  -o artifacts/copilot-stand.stl src/copilot-stand.scad

if command -v xvfb-run >/dev/null 2>&1; then
  xvfb-run -a openscad \
    -D stand_width=${STAND_WIDTH} \
    -D stand_depth=${STAND_DEPTH} \
    -D stand_height=${STAND_HEIGHT} \
    -D base_thickness=${BASE_THICKNESS} \
    -D pedestal_width=${PEDESTAL_WIDTH} \
    -D pedestal_depth=${PEDESTAL_DEPTH} \
    -D pedestal_height=${PEDESTAL_HEIGHT} \
    -D top_plate_thickness=${TOP_PLATE_THICKNESS} \
    -D nameplate_width=${NAMEPLATE_WIDTH} \
    -D nameplate_depth=${NAMEPLATE_DEPTH} \
    -D nameplate_height=${NAMEPLATE_HEIGHT} \
    -D mounting_hole_enabled=${MOUNTING_HOLE_ENABLED} \
    -D mounting_hole_diameter=${MOUNTING_HOLE_DIAMETER} \
    -D mounting_hole_pitch=${MOUNTING_HOLE_PITCH} \
    -D mounting_hole_margin=${MOUNTING_HOLE_MARGIN} \
    -D mounting_hole_depth=${MOUNTING_HOLE_DEPTH} \
    -o artifacts/copilot-stand.png --imgsize=1600,1200 src/copilot-stand.scad
else
  openscad \
    -D stand_width=${STAND_WIDTH} \
    -D stand_depth=${STAND_DEPTH} \
    -D stand_height=${STAND_HEIGHT} \
    -D base_thickness=${BASE_THICKNESS} \
    -D pedestal_width=${PEDESTAL_WIDTH} \
    -D pedestal_depth=${PEDESTAL_DEPTH} \
    -D pedestal_height=${PEDESTAL_HEIGHT} \
    -D top_plate_thickness=${TOP_PLATE_THICKNESS} \
    -D nameplate_width=${NAMEPLATE_WIDTH} \
    -D nameplate_depth=${NAMEPLATE_DEPTH} \
    -D nameplate_height=${NAMEPLATE_HEIGHT} \
    -D mounting_hole_enabled=${MOUNTING_HOLE_ENABLED} \
    -D mounting_hole_diameter=${MOUNTING_HOLE_DIAMETER} \
    -D mounting_hole_pitch=${MOUNTING_HOLE_PITCH} \
    -D mounting_hole_margin=${MOUNTING_HOLE_MARGIN} \
    -D mounting_hole_depth=${MOUNTING_HOLE_DEPTH} \
    -o artifacts/copilot-stand.png --imgsize=1600,1200 src/copilot-stand.scad
fi

PRUSA_SLICER_BIN="${PRUSA_SLICER_BIN:-$(command -v prusa-slicer || command -v prusa-slicer-console || true)}"
if [ -z "$PRUSA_SLICER_BIN" ] && [ -x "/Applications/PrusaSlicer.app/Contents/MacOS/PrusaSlicer" ]; then
  PRUSA_SLICER_BIN="/Applications/PrusaSlicer.app/Contents/MacOS/PrusaSlicer"
fi

if [ -n "$PRUSA_SLICER_BIN" ]; then
  "$PRUSA_SLICER_BIN" \
    --ignore-nonexistent-config \
    --load "$ROOT_DIR/profiles/vendor/HardwareDevOps.ini" \
    --output "$ROOT_DIR/artifacts/copilot-stand.gcode" \
    --export-gcode \
    --printer-profile "Home FDM (0.4 mm nozzle)" \
    --print-profile "0.20mm Standard @Home FDM (0.4 mm nozzle)" \
    --material-profile "Generic PLA @Home FDM (0.4 mm nozzle)" \
    "$ROOT_DIR/artifacts/copilot-stand.stl"

  python3 scripts/generate-manufacturing-report.py \
    --input "$ROOT_DIR/artifacts/copilot-stand.gcode" \
    --output "$ROOT_DIR/reports/copilot-stand-report.json"
fi

printf '\nBuild completed successfully.\n'
ls -lh artifacts/copilot-stand.stl artifacts/copilot-stand.png artifacts/copilot-stand.gcode reports/copilot-stand-report.json 2>/dev/null || ls -lh artifacts/copilot-stand.stl artifacts/copilot-stand.png
