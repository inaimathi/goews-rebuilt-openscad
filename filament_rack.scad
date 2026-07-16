include <BOSL2/std.scad>
include <constants.scad>
use <hanger_mount.scad>
use <hanger.scad>

/*
  GOEWS filament rack / rod rack.

  Coordinate convention:
    X = width along wall
    Y = projection out from wall
    Z = height

  bar_diameters:
    - If include_middle_holder=true:  [back, middle, front]
    - If include_middle_holder=false:
        [back, front] is accepted,
        or [back, ignored_middle, front] is also accepted.

  bar_notches:
    - Same indexing rules as bar_diameters.
    - A notch is modeled as a larger side pocket for a bar end-stop/collar.
*/

/* [Primary parameters] */

// Which GOEWS variant to use
variant = variant_thicker_cleats; // [0: Original, 1: Thicker cleats]

// Added to hanger fit, same idea as the GOEWS rebuilt parts
hanger_tolerance = 0.15;

// Add/remove center rod/bar holder
include_middle_holder = true;

// Rod/bar diameters in mm.
// Three entries means [back, middle, front].
bar_diameters = [25, 25, 25];

// Extra bottom thickness under each saddle, above the main base thickness
saddle_base_extra = 4;

/* [Holder notches] */

// Add centered collar/end-stop relief pockets to the saddles
bar_notches = [true, true, true];

// Width of the centered collar/end-stop relief along X
bar_notch_width = 10;

// Extra diameter for the centered collar/end-stop relief
bar_notch_diameter_extra = 7;

/* [Rack geometry] */

// Distance between rod/bar centers, front-to-back
bar_pitch = 80;

// Extra clearance around rods/bars
bar_clearance = 0.8;

// Wall thickness around the U-shaped cradles
holder_wall = 4;

// Width of each cradle along X
holder_width = 42;

// Extra lip above the rod centerline
holder_lip = 4;

// Base plate thickness
base_thickness = 8;

// Margin behind first holder and in front of last holder
back_margin = 8;
front_margin = 0;

// GOEWS hanger mount plate thickness
mount_plate_thickness = 8;

// Minimum GOEWS mount height. The actual height may be raised if needed.
mount_minimum_height = 100;

// Minimum GOEWS mount width. 42 gives one GOEWS plate unit; >42 snaps to more units.
mount_minimum_width = 42;

// Include the GOEWS bolt notch
mount_bolt_notch = true;

/* [Extra back cleats] */

// -1 = auto; 0 = only the default hanger_mount cleat row;
// positive values request that many extra rows, capped by available height.
extra_back_cleat_rows = -1; // [-1: Auto, 0: None, 1: One, 2: Two, 3: Three]

/* [Strength / printability] */

side_gussets = true;
gusset_thickness = 8;
gusset_margin = 3;
gusset_projection = 46;
gusset_height = 82;

// Distance above the open top of the rear bar cutout where side supports terminate
gusset_hole_clearance = 0.8;

// Raised center spine between saddles
center_connectors = true;
connector_width = 3;
connector_height = 25;
connector_overlap = 3;

front_stop_height = 6;
front_stop_thickness = 4;

/* [Rounding] */

base_rounding = 1.5;
saddle_rounding = 1.75;
connector_rounding = 1.5;
gusset_rounding = 0;

/* [Hidden] */

$fa = 0.5;
$fs = 0.5;
eps = 0.01;

function _vlast(v, i, fallback) =
  len(v) == 0
    ? fallback
    : v[i < len(v) ? i : len(v) - 1];

function _slot_value(v, slot, include_middle, fallback) =
  include_middle
    ? _vlast(v, slot, fallback)
    : (
        len(v) == 2
          ? _vlast(v, slot == 0 ? 0 : 1, fallback)
          : _vlast(v, slot, fallback)
      );

function _bar_diameter(v, slot, include_middle) =
  _slot_value(v, slot, include_middle, 22);

function _bar_notch(v, slot, include_middle) =
  _slot_value(v, slot, include_middle, true);

function _max3(a, b, c) = max(a, max(b, c));

function _holder_inner_for(d, clearance, notch_active, notch_extra) =
  d + clearance + (notch_active ? notch_extra : 0);

function _holder_od_for(d, clearance, wall, notch_active, notch_extra) =
  _holder_inner_for(d, clearance, notch_active, notch_extra) + 2 * wall;

function _holder_height_for(d, clearance, wall, base, lip, notch_active, notch_extra) =
  base + _holder_inner_for(d, clearance, notch_active, notch_extra) / 2 + wall + lip;

module rounded_xy_cube(size, r = 0) {
  rr = max(0, min(r, min(size[0], size[1]) / 2 - eps));

  if (rr <= 0) {
    cube(size);
  } else {
    translate([rr, rr, 0])
      linear_extrude(height = size[2])
        offset(r = rr)
          square([size[0] - 2 * rr, size[1] - 2 * rr]);
  }
}

module yz_rounded_prism(x0, w, pts, r = 0) {
  rr = max(0, r);

  // Local 2D polygon uses [Y, Z], then extrusion becomes world X.
  multmatrix([
    [0, 0, 1, x0],
    [1, 0, 0, 0],
    [0, 1, 0, 0],
    [0, 0, 0, 1]
  ])
    linear_extrude(height = w)
      if (rr > 0) {
        offset(r = rr)
          offset(delta = -rr)
            polygon(points = pts);
      } else {
        polygon(points = pts);
      }
}

module bar_tunnel_cut(
  d = 22,
  width = 42,
  base = 5,
  clearance = 0.8,
  notch_enabled = true,
  notch_width = 7,
  notch_diameter_extra = 7
) {
  inner = d + clearance;
  r = inner / 2;
  zc = base + r;

  // Main bar tunnel, axis along X.
  translate([0, 0, zc])
    rotate([0, 90, 0])
      cylinder(d = inner, h = width + 2 * eps, center = true);

  // Centered collar/end-stop relief.
  if (notch_enabled && notch_width > 0 && notch_diameter_extra > 0) {
    translate([0, 0, zc])
      rotate([0, 90, 0])
        cylinder(
          d = inner + notch_diameter_extra,
          h = notch_width + 2 * eps,
          center = true
        );
  }
}

module bar_open_top_cut(
  d = 22,
  width = 42,
  base = 5,
  clearance = 0.8,
  notch_enabled = true,
  notch_width = 7,
  notch_diameter_extra = 7,
  cut_height = 100
) {
  inner = d + clearance;
  r = inner / 2;
  zc = base + r;

  // Open the U-shaped saddle above the rod centerline.
  translate([-width / 2 - eps, -inner / 2, zc])
    cube([width + 2 * eps, inner, cut_height]);

  // Open the top of the centered collar/end-stop relief too.
  if (notch_enabled && notch_width > 0 && notch_diameter_extra > 0) {
    notch_inner = inner + notch_diameter_extra;

    translate([
      -notch_width / 2 - eps,
      -notch_inner / 2,
      zc
    ])
      cube([
        notch_width + 2 * eps,
        notch_inner,
        cut_height
      ]);
  }
}

module bar_saddle(
  d = 22,
  width = 42,
  wall = 4,
  base = 5,
  clearance = 0.8,
  lip = 4,
  notch_enabled = true,
  notch_width = 7,
  notch_diameter_extra = 7,
  rounding = 1.75
) {
  notch_active =
    notch_enabled && notch_width > 0 && notch_diameter_extra > 0;

  inner = d + clearance;
  outer_inner = inner + (notch_active ? notch_diameter_extra : 0);
  od = outer_inner + 2 * wall;
  h = base + outer_inner / 2 + wall + lip;

  difference() {
    translate([-width / 2, -od / 2, 0])
      rounded_xy_cube([width, od, h], r = rounding);

    bar_tunnel_cut(
      d = d,
      width = width + 2 * eps,
      base = base,
      clearance = clearance,
      notch_enabled = notch_enabled,
      notch_width = notch_width,
      notch_diameter_extra = notch_diameter_extra
    );

    bar_open_top_cut(
      d = d,
      width = width + 2 * eps,
      base = base,
      clearance = clearance,
      notch_enabled = notch_enabled,
      notch_width = notch_width,
      notch_diameter_extra = notch_diameter_extra
    );
  }
}

module side_volute(
  x0,
  w,
  wall_y,
  end_y,
  base_z,
  top_z,
  end_z,
  rounding = 1.25
) {
  if (top_z > end_z + 2 && end_y > wall_y + 2) {
    yz_rounded_prism(
      x0,
      w,
      [
        [wall_y, base_z],
        [wall_y, top_z],
        [end_y, end_z],
        [end_y, base_z]
      ],
      r = rounding
    );
  }
}

module center_connector(
  rack_width,
  y0,
  y1,
  base,
  height,
  width,
  rounding = 1.5
) {
  len_y = y1 - y0;

  if (len_y > eps && width > 0 && height > 0) {
    translate([rack_width / 2 - width / 2, y0, 0])
      rounded_xy_cube([width, len_y, base + height], r = rounding);
  }
}

module extra_back_hanger_rows(
  minimum_width = 42,
  mount_height = 74,
  variant = variant_thicker_cleats,
  hanger_tolerance = 0.15,
  requested_rows = -1
) {
  units = minimum_width ? get_hanger_units_from_width(minimum_width) : 1;

  // Match hanger_mount():
  //   needed_plate_height = minimum_height
  //   extend_bottom = needed_plate_height > plate_height
  //     ? needed_plate_height - plate_height
  //     : 0
  //
  // hanger_plate_unit() places the built-in/top hanger at Z = extend_bottom.
  // That Z coordinate is effectively the bottom of the cleat row.
  top_row_z = max(0, mount_height - plate_height);

  // Vertically aligned cleats need to skip one GOEWS hex row.
  // grid_tile_height is about 36.373mm, so this gives about 72.746mm
  // bottom-to-bottom.
  vertical_cleat_pitch = 2 * grid_tile_height;

  auto_rows = floor(top_row_z / vertical_cleat_pitch);

  row_count = requested_rows < 0
    ? auto_rows
    : min(requested_rows, auto_rows);

  if (row_count > 0) {
    for (row = [1 : row_count]) {
      row_z = top_row_z - row * vertical_cleat_pitch;

      // If there isn't room for the extra cleat row at the required spacing,
      // don't place it. This means the mount cleanly falls back to one cleat.
      if (row_z >= 0) {
        for (i = [0 : units - 1]) {
          translate([
            i * plate_width + (plate_width - hanger_width) / 2,
            0,
            row_z
          ])
            hanger(
              variant = variant,
              hanger_tolerance = hanger_tolerance,
              extended_bottom = row_z > 0
            );
        }
      }
    }
  }
}

module goews_filament_rack(
  include_middle_holder = true,
  bar_diameters = [22, 22, 22],
  bar_notches = [true, true, true],
  bar_notch_side = 2,
  bar_notch_width = 5,
  bar_notch_diameter_extra = 7,

  variant = variant_thicker_cleats,
  hanger_tolerance = 0.15,

  bar_pitch = 42,
  bar_clearance = 0.8,
  holder_wall = 4,
  holder_width = 42,
  holder_lip = 4,

  base_thickness = 5,
  back_margin = 10,
  front_margin = 8,

  mount_plate_thickness = 8,
  mount_minimum_height = 74,
  mount_minimum_width = 42,
  mount_bolt_notch = true,

  extra_back_cleat_rows = -1,

  front_stop_height = 6,
  front_stop_thickness = 4,

  side_gussets = true,
  gusset_thickness = 4,
  gusset_margin = 3,
  gusset_projection = 46,
  gusset_height = 56,
  gusset_hole_clearance = 0.8,

  center_connectors = true,
  connector_width = 18,
  connector_height = 10,
  connector_overlap = 3,

  base_rounding = 1.5,
  saddle_rounding = 1.75,
  connector_rounding = 1.5,
  gusset_rounding = 1.25
) {
  d0 = _bar_diameter(bar_diameters, 0, include_middle_holder);
  d1 = _bar_diameter(bar_diameters, 1, include_middle_holder);
  d2 = _bar_diameter(bar_diameters, 2, include_middle_holder);

  n0 = _bar_notch(bar_notches, 0, include_middle_holder);
  n1 = _bar_notch(bar_notches, 1, include_middle_holder);
  n2 = _bar_notch(bar_notches, 2, include_middle_holder);

  notch0 = n0 && bar_notch_width > 0 && bar_notch_diameter_extra > 0;
  notch1 = n1 && bar_notch_width > 0 && bar_notch_diameter_extra > 0;
  notch2 = n2 && bar_notch_width > 0 && bar_notch_diameter_extra > 0;

  saddle_base_thickness = base_thickness + saddle_base_extra;

  od0 = _holder_od_for(
    d0, bar_clearance, holder_wall, notch0, bar_notch_diameter_extra
  );

  od1 = _holder_od_for(
    d1, bar_clearance, holder_wall, notch1, bar_notch_diameter_extra
  );

  od2 = _holder_od_for(
    d2, bar_clearance, holder_wall, notch2, bar_notch_diameter_extra
  );

  h0 = _holder_height_for(
    d0, bar_clearance, holder_wall, saddle_base_thickness, holder_lip,
    notch0, bar_notch_diameter_extra
  );

  h1 = _holder_height_for(
    d1, bar_clearance, holder_wall, saddle_base_thickness, holder_lip,
    notch1, bar_notch_diameter_extra
  );

  h2 = _holder_height_for(
    d2, bar_clearance, holder_wall, saddle_base_thickness, holder_lip,
    notch2, bar_notch_diameter_extra
  );

  holder_od_max = include_middle_holder
    ? _max3(od0, od1, od2)
    : max(od0, od2);

  saddle_height = include_middle_holder
    ? _max3(h0, h1, h2)
    : max(h0, h2);

  rack_width = get_hanger_plate_width(mount_minimum_width);

  // hanger_mount/hanger_plate build positive Y from the rear hanger.
  plate_front_y =
    hanger_thickness
    + get_hanger_plate_offset(variant, hanger_tolerance)
    + mount_plate_thickness;

  rack_projection =
    back_margin
    + holder_od_max
    + 2 * bar_pitch
    + front_margin;

  first_holder_y =
    plate_front_y
    + back_margin
    + holder_od_max / 2;

  y0 = first_holder_y;
  y1 = first_holder_y + bar_pitch;
  y2 = first_holder_y + 2 * bar_pitch;

  mount_height = max(mount_minimum_height, saddle_height + 12);

  rear_bar_inner = d0 + bar_clearance;
  rear_bar_center_z = base_thickness + rear_bar_inner / 2;
  rear_bar_open_top_z = rear_bar_center_z + gusset_hole_clearance;

  difference() {
    union() {
      // GOEWS cleat/hanger support.
      hanger_mount(
		   holes = [],
		   plate_thickness = mount_plate_thickness,
		   minimum_width = mount_minimum_width,
		   minimum_height = mount_height,
		   bolt_notch = mount_bolt_notch,
		   bolt_notch_thickness = default_plate_thickness,
		   hanger_tolerance = hanger_tolerance,
		   variant = variant
		   );

      // Extra vertical cleat rows, when the backing plate is tall enough.
      extra_back_hanger_rows(
			     minimum_width = mount_minimum_width,
			     mount_height = mount_height,
			     variant = variant,
			     hanger_tolerance = hanger_tolerance,
			     requested_rows = extra_back_cleat_rows
			     );

      // Main horizontal arm/base.
      //
      // Extend the rounded base back into the vertical mount so the rear
      // rounded corners are buried inside the backing plate. This avoids
      // visible corner notches at the wall/base junction.
      base_back_overlap = max(base_rounding + 1, 2);

      translate([0, plate_front_y - base_back_overlap, 0])
	rounded_xy_cube(
			[
			 rack_width,
			 rack_projection + base_back_overlap + eps,
			 base_thickness
			 ],
			r = base_rounding
			);

      // Small front stop/lip.
      if (front_stop_height > 0) {
        translate([
		   0,
		   plate_front_y + rack_projection - front_stop_thickness,
		   0
		   ])
          rounded_xy_cube(
			  [
			   rack_width,
			   front_stop_thickness,
			   base_thickness + front_stop_height
			   ],
			  r = base_rounding
			  );
      }

      // Side volutes/gussets. These intentionally terminate at the top
      // of the rear bar opening, and the global bar tunnel cut below
      // guarantees they cannot block the rear rod.
      if (side_gussets) {
        gusset_end_y = min(first_holder_y, plate_front_y + gusset_projection);
        gusset_top_z = min(mount_height, gusset_height);

        side_volute(
		    gusset_margin,
		    gusset_thickness,
		    plate_front_y - eps,
		    gusset_end_y,
		    base_thickness,
		    gusset_top_z,
		    rear_bar_open_top_z,
		    rounding = gusset_rounding
		    );

        side_volute(
		    rack_width - gusset_margin - gusset_thickness,
		    gusset_thickness,
		    plate_front_y - eps,
		    gusset_end_y,
		    base_thickness,
		    gusset_top_z,
		    rear_bar_open_top_z,
		    rounding = gusset_rounding
		    );
      }

      // Raised center support/spine between saddles.
      if (center_connectors) {
        if (include_middle_holder) {
          center_connector(
			   rack_width,
			   y0 + od0 / 2 - connector_overlap,
			   y1 - od1 / 2 + connector_overlap,
			   base_thickness,
			   connector_height,
			   connector_width,
			   rounding = connector_rounding
			   );

          center_connector(
			   rack_width,
			   y1 + od1 / 2 - connector_overlap,
			   y2 - od2 / 2 + connector_overlap,
			   base_thickness,
			   connector_height,
			   connector_width,
			   rounding = connector_rounding
			   );
        } else {
          center_connector(
			   rack_width,
			   y0 + od0 / 2 - connector_overlap,
			   y2 - od2 / 2 + connector_overlap,
			   base_thickness,
			   connector_height,
			   connector_width,
			   rounding = connector_rounding
			   );
        }
      }

      // Back holder.
      translate([rack_width / 2, y0, 0])
        bar_saddle(
		   d = d0,
		   width = holder_width,
		   wall = holder_wall,
		   base = saddle_base_thickness,
		   clearance = bar_clearance,
		   lip = holder_lip,
		   notch_enabled = n0,
		   notch_width = bar_notch_width,
		   notch_diameter_extra = bar_notch_diameter_extra,
		   rounding = saddle_rounding
		   );

      // Optional middle holder.
      if (include_middle_holder) {
        translate([rack_width / 2, y1, 0])
          bar_saddle(
		     d = d1,
		     width = holder_width,
		     wall = holder_wall,
		     base = saddle_base_thickness,
		     clearance = bar_clearance,
		     lip = holder_lip,
		     notch_enabled = n1,
		     notch_width = bar_notch_width,
		     notch_diameter_extra = bar_notch_diameter_extra,
		     rounding = saddle_rounding
		     );
      }

      // Front holder.
      translate([rack_width / 2, y2, 0])
        bar_saddle(
		   d = d2,
		   width = holder_width,
		   wall = holder_wall,
		   base = saddle_base_thickness,
		   clearance = bar_clearance,
		   lip = holder_lip,
		   notch_enabled = n2,
		   notch_width = bar_notch_width,
		   notch_diameter_extra = bar_notch_diameter_extra,
		   rounding = saddle_rounding
		   );
    }

    // Global rod/cradle clearance cuts. This is the important hard-stopper fix:
    // side supports, connector ribs, and any other future geometry cannot
    // accidentally occlude the bar path OR the open top of the U-shaped saddle.
    translate([rack_width / 2, y0, 0]) {
      bar_tunnel_cut(
		     d = d0,
		     width = rack_width + 2 * eps,
		     base = saddle_base_thickness,
		     clearance = bar_clearance,
		     notch_enabled = n0,
		     notch_width = bar_notch_width,
		     notch_diameter_extra = bar_notch_diameter_extra
		     );

      bar_open_top_cut(
		       d = d0,
		       width = rack_width + 2 * eps,
		       base = saddle_base_thickness,
		       clearance = bar_clearance,
		       notch_enabled = n0,
		       notch_width = bar_notch_width,
		       notch_diameter_extra = bar_notch_diameter_extra,
		       cut_height = mount_height + saddle_height + 10
		       );
    }

    if (include_middle_holder) {
      translate([rack_width / 2, y1, 0]) {
	bar_tunnel_cut(
		       d = d1,
		       width = rack_width + 2 * eps,
		       base = saddle_base_thickness,
		       clearance = bar_clearance,
		       notch_enabled = n1,
		       notch_width = bar_notch_width,
		       notch_diameter_extra = bar_notch_diameter_extra
		       );

	bar_open_top_cut(
			 d = d1,
			 width = rack_width + 2 * eps,
			 base = saddle_base_thickness,
			 clearance = bar_clearance,
			 notch_enabled = n1,
			 notch_width = bar_notch_width,
			 notch_diameter_extra = bar_notch_diameter_extra,
			 cut_height = mount_height + saddle_height + 10
			 );
      }
    }

    translate([rack_width / 2, y2, 0]) {
      bar_tunnel_cut(
		     d = d2,
		     width = rack_width + 2 * eps,
		     base = saddle_base_thickness,
		     clearance = bar_clearance,
		     notch_enabled = n2,
		     notch_width = bar_notch_width,
		     notch_diameter_extra = bar_notch_diameter_extra
		     );

      bar_open_top_cut(
		       d = d2,
		       width = rack_width + 2 * eps,
		       base = saddle_base_thickness,
		       clearance = bar_clearance,
		       notch_enabled = n2,
		       notch_width = bar_notch_width,
		       notch_diameter_extra = bar_notch_diameter_extra,
		       cut_height = mount_height + saddle_height + 10
		       );
    }
  }
}

goews_filament_rack(
  include_middle_holder = include_middle_holder,
  bar_diameters = bar_diameters,
  bar_notches = bar_notches,
  bar_notch_side = bar_notch_side,
  bar_notch_width = bar_notch_width,
  bar_notch_diameter_extra = bar_notch_diameter_extra,

  variant = variant,
  hanger_tolerance = hanger_tolerance,

  bar_pitch = bar_pitch,
  bar_clearance = bar_clearance,
  holder_wall = holder_wall,
  holder_width = holder_width,
  holder_lip = holder_lip,

  base_thickness = base_thickness,
  back_margin = back_margin,
  front_margin = front_margin,

  mount_plate_thickness = mount_plate_thickness,
  mount_minimum_height = mount_minimum_height,
  mount_minimum_width = mount_minimum_width,
  mount_bolt_notch = mount_bolt_notch,

  extra_back_cleat_rows = extra_back_cleat_rows,

  front_stop_height = front_stop_height,
  front_stop_thickness = front_stop_thickness,

  side_gussets = side_gussets,
  gusset_thickness = gusset_thickness,
  gusset_margin = gusset_margin,
  gusset_projection = gusset_projection,
  gusset_height = gusset_height,
  gusset_hole_clearance = gusset_hole_clearance,

  center_connectors = center_connectors,
  connector_width = connector_width,
  connector_height = connector_height,
  connector_overlap = connector_overlap,

  base_rounding = base_rounding,
  saddle_rounding = saddle_rounding,
  connector_rounding = connector_rounding,
  gusset_rounding = gusset_rounding
);
