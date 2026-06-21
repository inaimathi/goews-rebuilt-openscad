include <BOSL2/std.scad>
include <BOSL2/shapes3d.scad>

include <constants.scad>
use <hanger.scad>


/* [Primary parameters] */
// Which variant to use
variant = 0; // [0: Original, 1: Thicker cleats]

// Added to hangers to allow for easier insertion and removal. This can be reduced to make hanger plates tighter to the tile. It reduces the tilt but makes them harder to insert and remove
hanger_tolerance = 0.15;


/* [Magazine parameters] */
// Number of magazines to hold
magazines = 4;

// Diameter of the cradle = the cross-section of the magazine that rests in the scoop. MEASURE YOURS and add a touch. (Rival mags vary by capacity, so this is a placeholder.)
mag_diameter = 33;

// Extra clearance added all the way around the magazine so it drops in/out easily
cradle_clearance = 1.0;

// How far the magazine nestles down into the cradle, measured from the top rim to the lowest point of the scoop.
//  - equal to the radius  => clean open half-pipe (easy in/out)
//  - greater than radius   => the side walls wrap further round the mag for more retention (slide it in from the open end)
//  - must stay below the full diameter or the cradle closes over completely
cradle_depth = 3;

// Length of each cradle channel, front-to-back (how much of the magazine's length is supported)
cradle_length = 42;

// Solid material left underneath the lowest point of each cradle
floor_thickness = 4;

// Rounding of the cradle channel mouth (front/back openings)
cradle_rounding = 1;


/* [Layout parameters] */
// Gap between cradles in mm
gap = 8;

// Gap/lip on the outward-facing end of the cradles. Set to 0 for an open front you can slide magazines straight into (like the reference part)
front_gap = 0;

// Gap/lip on the wall-facing end of the cradles
rear_gap = 0;

// Gap between the side of the holder and the outer cradles in mm
side_gap = 6;

// Rear fillet radius in mm (reinforces the joint to the hanger plate)
rear_fillet_radius = 2;

// Rounding on the outer top edges in mm
rounding = 0.5;


/* [Hidden] */
$fa=0.5;
$fs=0.5;


module mag_holder(
    variant=variant_original,
    magazines=4,
    mag_diameter=35,
    cradle_clearance=1.0,
    cradle_depth=22,
    cradle_length=60,
    floor_thickness=4,
    cradle_rounding=1,
    gap=8,
    front_gap=0,
    rear_gap=8,
    side_gap=6,
    rear_fillet_radius=2,
    rounding=0.5,
    hanger_tolerance=0.15
) {
    hanger_plate_offset = get_hanger_plate_offset(variant, hanger_tolerance);
    hanger_total_thickness = hanger_thickness + hanger_plate_offset;
    plate_total_thickness = default_plate_thickness + hanger_total_thickness;

    // Each cradle's footprint along the width (the opening), plus the side walls/gaps
    cradle_footprint = mag_diameter + cradle_clearance;
    cut_radius = cradle_footprint / 2;

    width = (side_gap * 2) + (magazines * cradle_footprint) + ((magazines - 1) * gap);
    depth = front_gap + rear_gap + cradle_length + 8;

    // Tall enough to contain the cradle depth plus the solid floor beneath it
    block_height = floor_thickness + cradle_depth;
    // Height of the magazine's centre: its lowest point rests floor_thickness above the base
    mag_center_z = floor_thickness + cut_radius;

    x_offset = get_hanger_plate_width(width) / 2;
    y_offset = plate_total_thickness;

    union() {
        hanger_plate(
            variant=variant,
            hanger_units=get_hanger_units_from_width(width),
            hanger_tolerance=hanger_tolerance
        );

        // Holder body + cradle scoops
        difference() {
	  translate([x_offset, y_offset, 0]) {
	    cuboid(
		   [width, depth, block_height],
		   anchor=BOTTOM+FRONT,
		   rounding=rounding,
		   edges=[BACK]
		   );
	  }

            shelf_x_offset = ((get_hanger_plate_width(width) - width) / 2);
            translate([shelf_x_offset, y_offset, 0]) {
                for (m = [0 : magazines - 1]) {
		  cradle_x = side_gap + m * (cradle_footprint + gap) + cradle_footprint / 2;
		  // Half-pipe scoop: a cylinder lying along the depth (Y) axis,
		  // subtracted from the top of the body.
		  translate([cradle_x, rear_gap + cradle_length / 2, -mag_center_z]) {
		    translate([-4, -(mag_diameter/2-1), 0]) cube([8, 9, 60]);
		    notch=mag_diameter+5;
		    n2 = notch-5;
		    translate([-notch/2, 8, 0]) cube([notch, 9, 60]);
		    translate([-n2/2, 15, 0]) cube([n2, 9, 60]);
		    translate([0, 9, 0]) linear_extrude(60) circle(r=mag_diameter/2);
		  }
                }
            }
        }

        // Rear fillet reinforcing the body-to-plate joint
        translate([x_offset, y_offset, block_height]) {
            fillet(l=width, r=rear_fillet_radius, orient=LEFT);
        }
    }
}


mag_holder(
    variant=variant,
    magazines=magazines,
    mag_diameter=mag_diameter,
    cradle_clearance=cradle_clearance,
    cradle_depth=cradle_depth,
    cradle_length=cradle_length,
    floor_thickness=floor_thickness,
    cradle_rounding=cradle_rounding,
    gap=gap,
    front_gap=front_gap,
    rear_gap=rear_gap,
    side_gap=side_gap,
    rear_fillet_radius=rear_fillet_radius,
    rounding=rounding,
    hanger_tolerance=hanger_tolerance
);
