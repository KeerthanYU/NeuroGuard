// ============================================================
//  Seizure Detection Wearable — COMBINED PRINT LAYOUT
//  Base + Lid side by side, both flat on print bed
//  Send the exported STL directly to your printing company.
//  Open this file in OpenSCAD to preview before sending.
// ============================================================

$fn = 64;

// ── SHELL DIMENSIONS ────────────────────────────────────────
ext_l      = 80;
ext_w      = 65;
base_h     = 46;
lid_h      = 10;
corner_r   = 8;
wall_t     = 2.4;

// ── DERIVED ─────────────────────────────────────────────────
int_l      = ext_l - 2 * wall_t;
int_w      = ext_w - 2 * wall_t;
int_h_base = base_h - wall_t;

// ── SNAP-FIT ────────────────────────────────────────────────
lip_h       = 4.0;
lip_inset   = wall_t;
lip_gap     = 0.25;
snap_depth  = 1.0;
snap_bead_h = 1.2;

// ── CUTOUTS ─────────────────────────────────────────────────
sensor_d    = 14;
usb_w       = 12;
usb_h       = 8;
ant_d       = 5;
ant_z       = base_h * 0.65;

// ── DISPLAY WINDOW ───────────────────────────────────────────
oled_win_l    = 26;
oled_win_w    = 26;
oled_corner_r = 1.5;

// ── STRAP LUGS ───────────────────────────────────────────────
lug_slot_w = 24;
lug_slot_h = 4;
lug_depth  = wall_t;
lug_ear_h  = base_h;

// ── LAYOUT GAP between the two parts on the bed ─────────────
part_gap   = 12;

// ============================================================
//  UTILITIES
// ============================================================
module rrs(l, w, h, r) {
    safe_r = min(r, min(l,w)/2 - 0.01);
    minkowski() {
        cube([l-2*safe_r, w-2*safe_r, h], center=true);
        cylinder(r=safe_r, h=0.001, center=true);
    }
}

module rrs_cutout(l, w, h, r) {
    safe_r = min(r, min(l,w)/2 - 0.01);
    minkowski() {
        cube([l-2*safe_r, w-2*safe_r, h+2], center=true);
        cylinder(r=safe_r, h=0.001, center=true);
    }
}

module hollow_shell(o_l, o_w, o_h, i_l, i_w, i_h, r) {
    difference() {
        translate([0, 0, o_h/2])
            rrs(o_l, o_w, o_h, r);
        translate([0, 0, wall_t + i_h/2])
            rrs(i_l, i_w, i_h+0.01, r-wall_t);
    }
}

// ============================================================
//  BASE MODULE
// ============================================================
module base() {
    difference() {
        union() {
            hollow_shell(ext_l, ext_w, base_h,
                         int_l, int_w, int_h_base, corner_r);
            for (side=[-1,1])
                translate([side*(ext_l/2+lug_depth/2), 0, lug_ear_h/2])
                    cube([lug_depth, ext_w, lug_ear_h], center=true);
        }
        // Sensor hole
        translate([0, 0, -0.5])
            cylinder(d=sensor_d, h=wall_t+1);
        // USB port — Y- face
        translate([0, -(ext_w/2)-0.5, base_h/2])
            cube([usb_w, wall_t+1.5, usb_h], center=true);
        // Antenna hole — Y+ face
        translate([0, (ext_w/2)+0.5, ant_z])
            rotate([90,0,0]) cylinder(d=ant_d, h=wall_t+1.5);
        // Snap groove
        translate([0, 0, base_h-lip_h/2])
            difference() {
                rrs_cutout(int_l+2*lip_gap, int_w+2*lip_gap,
                           lip_h, corner_r-wall_t);
                rrs_cutout(int_l-2*lip_inset, int_w-2*lip_inset,
                           lip_h+4, corner_r-wall_t-lip_inset);
            }
        // Snap bead undercut
        translate([0, 0, base_h-lip_h/2-snap_bead_h/2-lip_gap])
            difference() {
                rrs_cutout(int_l+2*(lip_gap+snap_depth),
                           int_w+2*(lip_gap+snap_depth),
                           snap_bead_h, corner_r-wall_t);
                rrs_cutout(int_l+2*lip_gap-0.02,
                           int_w+2*lip_gap-0.02,
                           snap_bead_h+2, corner_r-wall_t);
            }
        // Lug slots
        for (side=[-1,1])
            translate([side*(ext_l/2+lug_depth/2), 0,
                       lug_slot_h/2+wall_t+2])
                cube([lug_depth+1, lug_slot_w, lug_slot_h], center=true);
    }
}

// ============================================================
//  LID MODULE
// ============================================================
module lid() {
    difference() {
        union() {
            // Body
            translate([0,0,lid_h/2])
                rrs(ext_l, ext_w, lid_h, corner_r);
            // Snap lip
            translate([0,0,-lip_h/2])
                difference() {
                    rrs(int_l+2*lip_gap-0.01,
                        int_w+2*lip_gap-0.01,
                        lip_h, corner_r-wall_t);
                    rrs(int_l-2*lip_inset+0.01,
                        int_w-2*lip_inset+0.01,
                        lip_h+0.02, corner_r-wall_t-lip_inset);
                }
            // Snap bead
            translate([0,0,-snap_bead_h/2-lip_h/2+1.2])
                difference() {
                    rrs(int_l+2*(lip_gap+snap_depth)-0.01,
                        int_w+2*(lip_gap+snap_depth)-0.01,
                        snap_bead_h, corner_r-wall_t);
                    rrs(int_l+2*lip_gap,
                        int_w+2*lip_gap,
                        snap_bead_h+0.02, corner_r-wall_t);
                }
            // Lead-in chamfer
            translate([0,0,-lip_h-0.4])
                difference() {
                    rrs(int_l+2*(lip_gap+snap_depth)+1.5,
                        int_w+2*(lip_gap+snap_depth)+1.5,
                        1.2, corner_r-wall_t);
                    rrs(int_l+2*lip_gap-1.0,
                        int_w+2*lip_gap-1.0,
                        1.3, corner_r-wall_t);
                }
        }
        // OLED window
        translate([0,0,lid_h/2])
            rrs_cutout(oled_win_l, oled_win_w, lid_h, oled_corner_r);
    }
}

// ============================================================
//  COMBINED PRINT LAYOUT
//  Both parts centred together, gap between them.
//  Base  → left,  flat bottom on bed (Z=0)
//  Lid   → right, flipped 180° so flat top face on bed (Z=0)
//
//  Total bed footprint:
//    X : 84.8 (base+lugs) + 12 (gap) + 80 (lid) = 176.8 mm
//    Y : 65 mm
// ============================================================

base_x_offset = -(ext_l/2 + lug_depth + part_gap/2);
lid_x_offset  =  (ext_l/2 + part_gap/2);

// BASE — sits naturally, flat bottom on bed
translate([base_x_offset, 0, 0])
    base();

// LID — flipped so flat top face touches bed,
//        lip and snap bead point upward (no supports needed)
translate([lid_x_offset, 0, lid_h])
    rotate([180, 0, 0])
        lid();

// ============================================================
//  PART LABELS (extruded text, 0.6 mm proud of bed)
//  Helps you identify parts after print — can be sanded off.
// ============================================================
translate([base_x_offset, -ext_w/2 + 6, 0.3])
    linear_extrude(0.6)
        text("BASE", size=5, halign="center", font="Liberation Sans:Bold");

translate([lid_x_offset, -ext_w/2 + 6, 0.3])
    linear_extrude(0.6)
        text("LID", size=5, halign="center", font="Liberation Sans:Bold");
