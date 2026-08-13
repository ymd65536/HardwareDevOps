#!/usr/bin/env python3
import argparse
import json
import re
from datetime import datetime, timezone
from pathlib import Path


TIME_RE = re.compile(r"(?:(\d+)h)?\s*(?:(\d+)m|min)?\s*(?:(\d+)s)?")
FLOAT_RE = re.compile(r"[-+]?\d*\.?\d+")


def parse_print_time(raw_value: str) -> int:
    text = raw_value.strip()
    match = TIME_RE.search(text)
    if not match:
        raise ValueError(f"Unable to parse print time value: {raw_value!r}")
    hours, minutes, seconds = match.groups()
    total_minutes = 0
    if hours:
        total_minutes += int(hours) * 60
    if minutes:
        total_minutes += int(minutes)
    if seconds and not minutes and not hours:
        total_minutes += int(seconds) // 60
    return total_minutes


def parse_float(value: str):
    match = FLOAT_RE.search(value)
    if match is None:
        raise ValueError(f"Unable to parse numeric value: {value!r}")
    return float(match.group(0))


def parse_int(value: str):
    match = re.search(r"\d+", value)
    if match is None:
        raise ValueError(f"Unable to parse integer value: {value!r}")
    return int(match.group(0))


def extract_value(text: str):
    if "=" not in text:
        return None
    _, value = text.split("=", 1)
    return value.strip()


def parse_metadata(gcode_path: Path):
    metadata = {
        "source_file": str(gcode_path),
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "printer_model": None,
        "material": None,
        "print_time_minutes": None,
        "filament_mm": None,
        "filament_cm3": None,
        "filament_g": None,
        "layer_count": None,
        "nozzle_diameter": None,
        "notes": [
            "This report captures slicer metadata only. It does not certify print safety or manufacturability."
        ],
    }

    for raw_line in gcode_path.read_text(encoding="utf-8", errors="replace").splitlines():
        line = raw_line.strip()
        if not line.startswith(";"):
            continue
        text = line[1:].strip()
        lower_text = text.lower()

        if "estimated printing time" in lower_text or "print time" in lower_text or "time_elapsed" in lower_text:
            value = extract_value(text)
            if value is not None:
                metadata["print_time_minutes"] = parse_print_time(value)
        elif "filament used [mm]" in lower_text or "filament_used_mm" in lower_text:
            value = extract_value(text)
            if value is not None:
                metadata["filament_mm"] = parse_float(value)
        elif "filament used [cm3]" in lower_text or "filament_used_cm3" in lower_text:
            value = extract_value(text)
            if value is not None:
                metadata["filament_cm3"] = parse_float(value)
        elif "filament used [g]" in lower_text or "filament_used_g" in lower_text:
            value = extract_value(text)
            if value is not None:
                metadata["filament_g"] = parse_float(value)
        elif "layer_count" in lower_text or "total layers" in lower_text:
            value = extract_value(text)
            if value is not None:
                metadata["layer_count"] = parse_int(value)
        elif "nozzle_diameter" in lower_text:
            value = extract_value(text)
            if value is not None:
                metadata["nozzle_diameter"] = parse_float(value)
        elif "printer_model" in lower_text:
            value = extract_value(text)
            if value is not None:
                metadata["printer_model"] = value.strip()
        elif "material" in lower_text:
            value = extract_value(text)
            if value is not None:
                metadata["material"] = value.strip()

    # Bambu Studio commonly emits uppercase keys but with the same semantics.
    for label in ("PRINTER_MODEL", "MATERIAL", "NOZZLE_DIAMETER", "LAYER_COUNT", "FILAMENT_USED_MM", "FILAMENT_USED_CM3", "FILAMENT_USED_G", "TIME_ELAPSED"):
        found = False
        for raw_line in gcode_path.read_text(encoding="utf-8", errors="replace").splitlines():
            line = raw_line.strip()
            if not line.startswith(";"):
                continue
            text = line[1:].strip()
            if text.upper().startswith(label + " ="):
                value = extract_value(text)
                if value is None:
                    continue
                if label == "PRINTER_MODEL":
                    metadata["printer_model"] = value.strip()
                elif label == "MATERIAL":
                    metadata["material"] = value.strip()
                elif label == "NOZZLE_DIAMETER":
                    metadata["nozzle_diameter"] = parse_float(value)
                elif label == "LAYER_COUNT":
                    metadata["layer_count"] = parse_int(value)
                elif label == "FILAMENT_USED_MM":
                    metadata["filament_mm"] = parse_float(value)
                elif label == "FILAMENT_USED_CM3":
                    metadata["filament_cm3"] = parse_float(value)
                elif label == "FILAMENT_USED_G":
                    metadata["filament_g"] = parse_float(value)
                elif label == "TIME_ELAPSED":
                    metadata["print_time_minutes"] = parse_print_time(value)
                found = True
                break
        if found:
            break

    return metadata


def main():
    parser = argparse.ArgumentParser(description="Generate a JSON manufacturing report from a slicer G-code export.")
    parser.add_argument("--input", type=Path, required=True, help="Path to the generated G-code file")
    parser.add_argument("--output", type=Path, required=True, help="Path to the JSON report output")
    args = parser.parse_args()

    if not args.input.exists():
        raise FileNotFoundError(f"Input G-code file does not exist: {args.input}")

    metadata = parse_metadata(args.input)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(metadata, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"Wrote manufacturing report to {args.output}")


if __name__ == "__main__":
    main()
