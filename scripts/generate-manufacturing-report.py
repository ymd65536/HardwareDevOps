#!/usr/bin/env python3
import argparse
import json
import re
import zipfile
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


def extract_value_from_text(text: str):
    if "=" in text:
        _, value = text.split("=", 1)
        return value.strip()
    if ":" in text:
        _, value = text.split(":", 1)
        return value.strip()
    return text.strip()


def parse_3mf_metadata(three_mf_path: Path):
    metadata = {
        "printer_model": None,
        "material": None,
        "print_time_minutes": None,
        "filament_mm": None,
        "filament_cm3": None,
        "filament_g": None,
        "layer_count": None,
        "nozzle_diameter": None,
    }

    try:
        with zipfile.ZipFile(three_mf_path, "r") as zf:
            names = [name for name in zf.namelist() if name.lower().endswith(".model") or name.lower().endswith(".xml")]
            if not names:
                return metadata
            xml_text = zf.read(names[0]).decode("utf-8", errors="replace")
    except zipfile.BadZipFile:
        return metadata

    def read_metadata_field(name: str):
        match = re.search(rf'<metadata[^>]*name=["\']{re.escape(name)}["\'][^>]*>(.*?)</metadata>', xml_text, flags=re.IGNORECASE | re.DOTALL)
        if not match:
            return None
        return match.group(1).strip()

    fields = {
        "PrintTime": ("print_time_minutes", lambda v: parse_print_time(v)),
        "FilamentLength": ("filament_mm", lambda v: parse_float(v)),
        "FilamentVolume": ("filament_cm3", lambda v: parse_float(v)),
        "FilamentWeight": ("filament_g", lambda v: parse_float(v)),
        "LayerCount": ("layer_count", lambda v: parse_int(v)),
        "NozzleDiameter": ("nozzle_diameter", lambda v: parse_float(v)),
        "PrinterModel": ("printer_model", lambda v: v or None),
        "Material": ("material", lambda v: v or None),
    }

    for field_name, (key, parser) in fields.items():
        value = read_metadata_field(field_name)
        if value is None:
            continue
        metadata[key] = parser(value)

    return metadata


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

    if gcode_path.suffix.lower() == ".3mf":
        metadata.update(parse_3mf_metadata(gcode_path))
        return metadata

    lines = gcode_path.read_text(encoding="utf-8", errors="replace").splitlines()

    for raw_line in lines:
        line = raw_line.strip()
        if not line.startswith(";"):
            continue
        text = line[1:].strip()
        lower_text = text.lower()

        if "estimated printing time" in lower_text or "time_elapsed" in lower_text:
            value = extract_value_from_text(text)
            if value:
                metadata["print_time_minutes"] = parse_print_time(value)
        elif "total filament length" in lower_text or "filament used [mm]" in lower_text or "filament_used_mm" in lower_text:
            value = extract_value_from_text(text)
            if value:
                metadata["filament_mm"] = parse_float(value)
        elif "total filament volume" in lower_text or "filament used [cm3]" in lower_text or "filament_used_cm3" in lower_text:
            value = extract_value_from_text(text)
            if value:
                metadata["filament_cm3"] = parse_float(value)
        elif "total filament weight" in lower_text or "filament used [g]" in lower_text or "filament_used_g" in lower_text:
            value = extract_value_from_text(text)
            if value:
                metadata["filament_g"] = parse_float(value)
        elif "interlocking_beam_layer_count" in lower_text:
            continue
        elif "total layer number" in lower_text or "total layers" in lower_text or "layer_count" in lower_text:
            value = extract_value_from_text(text)
            if value:
                metadata["layer_count"] = parse_int(value)
        elif "nozzle_diameter" in lower_text:
            value = extract_value_from_text(text)
            if value:
                metadata["nozzle_diameter"] = parse_float(value)
        elif "printer_model" in lower_text:
            value = extract_value_from_text(text)
            if value is not None:
                normalized = value.strip()
                if normalized:
                    metadata["printer_model"] = normalized
                elif metadata["printer_model"] is None:
                    metadata["printer_model"] = None
        elif "filament_type" in lower_text or ("material" in lower_text and not "filament" in lower_text):
            value = extract_value_from_text(text)
            if value:
                metadata["material"] = value.strip() or None

    for label in ("PRINTER_MODEL", "MATERIAL", "NOZZLE_DIAMETER", "LAYER_COUNT", "FILAMENT_USED_MM", "FILAMENT_USED_CM3", "FILAMENT_USED_G", "TIME_ELAPSED"):
        for raw_line in lines:
            line = raw_line.strip()
            if not line.startswith(";"):
                continue
            text = line[1:].strip()
            if text.upper().startswith(label + " ="):
                value = extract_value(text)
                if value is None:
                    continue
                if label == "PRINTER_MODEL":
                    normalized = value.strip()
                    metadata["printer_model"] = normalized or None
                elif label == "MATERIAL":
                    normalized = value.strip()
                    metadata["material"] = normalized or None
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
