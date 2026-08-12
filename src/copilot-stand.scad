// GitHub Copilot figure display stand (PoC)
// All dimensions are in millimeters.

$fn = 48;

// Main design parameters.
stand_width = 90;
stand_depth = 70;
stand_height = 46;
base_thickness = 5;
pedestal_width = 58;
pedestal_depth = 44;
pedestal_height = 22;
top_plate_thickness = 4;
nameplate_width = 34;
nameplate_depth = 12;
nameplate_height = 2;
clearance_margin = 1.5;
mounting_slot_length = 18;
mounting_slot_width = 5;
mounting_slot_depth = 14;
mounting_hole_enabled = true;
mounting_hole_diameter = 3.2;
mounting_hole_pitch = 48;
mounting_hole_margin = 8;
mounting_hole_depth = 12;

// A reserved extension zone for future hardware features like mounting holes,
// a magnet pocket, or a modular accessory base.
module future_mounting_zone() {
    slot_z = base_thickness + 2;
    slot_y = (stand_depth - mounting_slot_length) / 2;

    translate([stand_width * 0.18, slot_y, slot_z])
        cube([mounting_slot_width, mounting_slot_length, mounting_slot_depth], center = false);

    translate([stand_width * 0.82 - mounting_slot_width, slot_y, slot_z])
        cube([mounting_slot_width, mounting_slot_length, mounting_slot_depth], center = false);
}

module mounting_feature() {
    if (mounting_hole_enabled) {
        y = stand_depth - mounting_hole_margin;
        x_left = (stand_width - mounting_hole_pitch) / 2;
        x_right = x_left + mounting_hole_pitch;
        z_start = -1;

        translate([x_left, y, z_start])
            cylinder(h = base_thickness + mounting_hole_depth, d = mounting_hole_diameter);

        translate([x_right, y, z_start])
            cylinder(h = base_thickness + mounting_hole_depth, d = mounting_hole_diameter);
    }
}

module base_block() {
    cube([stand_width, stand_depth, base_thickness], center = false);
}

module main_pedestal() {
    x = (stand_width - pedestal_width) / 2;
    y = (stand_depth - pedestal_depth) / 2;
    z = base_thickness;

    translate([x, y, z])
        cube([pedestal_width, pedestal_depth, pedestal_height], center = false);
}

module top_plate() {
    x = (stand_width - pedestal_width) / 2;
    y = (stand_depth - pedestal_depth) / 2;
    z = base_thickness + pedestal_height;

    translate([x, y, z])
        cube([pedestal_width, pedestal_depth, top_plate_thickness], center = false);
}

module name_plate_zone() {
    x = (stand_width - nameplate_width) / 2;
    y = stand_depth - nameplate_depth - 1;
    z = base_thickness + pedestal_height - nameplate_height;

    translate([x, y, z])
        cube([nameplate_width, nameplate_depth, nameplate_height], center = false);
}

module display_stand() {
    difference() {
        union() {
            base_block();
            main_pedestal();
            top_plate();
            name_plate_zone();
            future_mounting_zone();
        }
        mounting_feature();
    }
}

// Render the independent display stand.
display_stand();
