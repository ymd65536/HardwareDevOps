#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "This manufacturing pipeline is Linux-only. Use the pinned Docker toolchain or run inside an Ubuntu-based container." >&2
  exit 1
fi

resolve_tool() {
  local tool_name="$1"
  shift || true
  local fallback="${1:-}"

  if command -v "$tool_name" >/dev/null 2>&1; then
    command -v "$tool_name"
    return 0
  fi

  if [[ -n "$fallback" ]] && [[ -x "$fallback" ]]; then
    printf '%s\n' "$fallback"
    return 0
  fi

  return 1
}

validate_required_profiles() {
  local missing=0
  for dir in "$ROOT_DIR/profiles/machine" "$ROOT_DIR/profiles/process" "$ROOT_DIR/profiles/filament"; do
    if [[ ! -d "$dir" ]]; then
      echo "Required repository-managed Bambu profile directory not found: $dir" >&2
      missing=1
    fi
  done

  if [[ "$missing" -ne 0 ]]; then
    exit 1
  fi
}

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
validate_required_profiles

OPENSCAD_BIN="$(resolve_tool openscad "" || true)"
BAMBU_STUDIO_BIN="${BAMBU_STUDIO_BIN:-}"
if [[ -z "$BAMBU_STUDIO_BIN" ]]; then
  BAMBU_STUDIO_BIN="$(resolve_tool bambu-studio "" || true)"
fi
if [[ -z "$BAMBU_STUDIO_BIN" ]]; then
  BAMBU_STUDIO_BIN="$(find "$ROOT_DIR" -type f \( -name 'bambu-studio' -o -name 'AppRun' -o -name '*.AppImage' \) -print -quit 2>/dev/null || true)"
fi
if [[ -z "$BAMBU_STUDIO_BIN" ]]; then
  echo "Bambu Studio CLI not found in PATH or repo. Install the official Linux AppImage or set BAMBU_STUDIO_BIN to the executable." >&2
  exit 1
fi

if [[ "$BAMBU_STUDIO_BIN" == *"/AppRun" || "$BAMBU_STUDIO_BIN" == *".AppImage" ]]; then
  export LD_LIBRARY_PATH="/opt/bambu/squashfs-root/bin:/usr/lib/x86_64-linux-gnu:/lib/x86_64-linux-gnu${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
fi

if [[ -z "$OPENSCAD_BIN" ]]; then
  echo "OpenSCAD CLI not found in PATH. Install OpenSCAD before running this build." >&2
  exit 1
fi

if command -v xvfb-run >/dev/null 2>&1; then
  BAMBU_HELP_OUTPUT="$(xvfb-run -a env LD_LIBRARY_PATH="$LD_LIBRARY_PATH" "$BAMBU_STUDIO_BIN" --help 2>&1 || true)"
else
  BAMBU_HELP_OUTPUT="$(env LD_LIBRARY_PATH="$LD_LIBRARY_PATH" "$BAMBU_STUDIO_BIN" --help 2>&1 || true)"
fi
if ! printf '%s\n' "$BAMBU_HELP_OUTPUT" | grep -q -- '--slice' || ! printf '%s\n' "$BAMBU_HELP_OUTPUT" | grep -q -- '--outputdir'; then
  echo "Unsupported Bambu Studio CLI detected. This project expects the Linux AppImage with --slice and --outputdir support." >&2
  exit 1
fi

printf 'OpenSCAD: %s\n' "$OPENSCAD_BIN"
printf 'Bambu Studio: %s\n' "$BAMBU_STUDIO_BIN"
printf '\n== Version check ==\n'
if "$OPENSCAD_BIN" --version >/dev/null 2>&1; then
  "$OPENSCAD_BIN" --version
else
  "$OPENSCAD_BIN" -v
fi

if "$BAMBU_STUDIO_BIN" --version >/dev/null 2>&1; then
  "$BAMBU_STUDIO_BIN" --version
else
  "$BAMBU_STUDIO_BIN" --help 2>&1 | head -n 20 || true
fi

python3 scripts/validate-stand.py

"$OPENSCAD_BIN" \
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
  xvfb-run -a "$OPENSCAD_BIN" \
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
  "$OPENSCAD_BIN" \
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

# Bambu Studio CLI accepts headless slicing with the STL directly in the output folder.
if command -v xvfb-run >/dev/null 2>&1; then
  xvfb-run -a env XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" LD_LIBRARY_PATH="$LD_LIBRARY_PATH" "$BAMBU_STUDIO_BIN" \
    --outputdir "$ROOT_DIR/artifacts" \
    --slice 0 \
    "$ROOT_DIR/artifacts/copilot-stand.stl"
else
  env XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" LD_LIBRARY_PATH="$LD_LIBRARY_PATH" "$BAMBU_STUDIO_BIN" \
    --outputdir "$ROOT_DIR/artifacts" \
    --slice 0 \
    "$ROOT_DIR/artifacts/copilot-stand.stl"
fi

REPORT_INPUT=""
if find "$ROOT_DIR/artifacts" -maxdepth 1 -type f \( -name '*.gcode' -o -name '*.GCODE' \) 2>/dev/null | grep -q .; then
  REPORT_INPUT="$(find "$ROOT_DIR/artifacts" -maxdepth 1 -type f \( -name '*.gcode' -o -name '*.GCODE' \) | sort | head -n 1)"
elif find "$ROOT_DIR/artifacts" -maxdepth 1 -type f \( -name '*.3mf' -o -name '*.3MF' \) 2>/dev/null | grep -q .; then
  REPORT_INPUT="$(find "$ROOT_DIR/artifacts" -maxdepth 1 -type f \( -name '*.3mf' -o -name '*.3MF' \) | sort | head -n 1)"
elif [[ -f "$ROOT_DIR/artifacts/result.json" ]]; then
  REPORT_INPUT="$ROOT_DIR/artifacts/result.json"
fi

if [[ -n "$REPORT_INPUT" ]]; then
  python3 scripts/generate-manufacturing-report.py \
    --input "$REPORT_INPUT" \
    --output "$ROOT_DIR/reports/copilot-stand-report.json"
else
  echo "No slicer output artifact was found under artifacts/; report generation skipped." >&2
  exit 1
fi

printf '\nBuild completed successfully.\n'
ls -lh artifacts/copilot-stand.stl artifacts/copilot-stand.png reports/copilot-stand-report.json 2>/dev/null || true
