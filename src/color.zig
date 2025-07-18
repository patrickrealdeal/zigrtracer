const std = @import("std");
const Vec3 = @import("vector3.zig");
pub const Color = Vec3.Vec3;

const clamp = std.math.clamp;

pub fn write_color(out: anytype, pixel_color: *Color) !void {
    const r = pixel_color[0];
    const g = pixel_color[1];
    const b = pixel_color[2];

    // Translate the [0,1] component values to the byte range [0,255]
    const rbyte: u32 = @intFromFloat(256 * clamp(r, 0.000, 0.999));
    const gbyte: u32 = @intFromFloat(256 * clamp(g, 0.000, 0.999));
    const bbyte: u32 = @intFromFloat(256 * clamp(b, 0.000, 0.999));

    try out.print("{d} {d} {d}\n", .{ rbyte, gbyte, bbyte });
}
