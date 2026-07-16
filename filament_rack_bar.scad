/*
  filament_rack_bar.scad

  Bar for GOEWS filament rack saddles.

  Length modes:
    bar_length_mode = "mm"     -> use bar_length_mm directly
    bar_length_mode = "steps"  -> use bar_length_steps

  Step lengths:
    1   == 124mm
    1.5 == halfway between 124mm and 210mm == 167mm
    2   == 210mm
*/

/* [Bar] */

bar_diameter = 25;
bar_thickness = 3;
bar_end_diameter = 28;
bar_end_length = 4;

/* [Length] */

// "mm" or "steps"
bar_length_mode = "steps";

// Used when bar_length_mode == "mm"
bar_length_mm = 210;

// Used when bar_length_mode == "steps"
// Valid intended values: 1, 1.5, 2
bar_length_steps = 2;

// Step calibration
bar_length_1_step = 124;
bar_length_2_steps = 210;

function bar_length_from_steps(steps) =
  bar_length_1_step
  + ((steps - 1) * (bar_length_2_steps - bar_length_1_step));

function resolved_bar_length() =
  bar_length_mode == "steps"
    ? bar_length_from_steps(bar_length_steps)
    : bar_length_mm;

module goews_filament_rack_bar(d, d2, t, l, l2) {
  $fn = 64;
  delta = d2 - d;

  difference() {
    union() {
      cylinder(d=d, h=l);

      hull() {
        cylinder(d=d2, h=l2);
        translate([0, 0, l2 + delta])
          cylinder(d=d, h=0.1);
      }

      hull() {
        translate([0, 0, l - l2])
          cylinder(d=d2, h=l2);
        translate([0, 0, l - l2 - delta])
          cylinder(d=d, h=0.1);
      }
    }

    translate([0, 0, -1])
      cylinder(d=d - t, h=l + 2);
  }
}

goews_filament_rack_bar(
  bar_diameter,
  bar_end_diameter,
  bar_thickness,
  resolved_bar_length(),
  bar_end_length
);
