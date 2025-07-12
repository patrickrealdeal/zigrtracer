const std = @import("std");
const vec3 = @import("vector3.zig");
const Point = vec3.Point;

const Self = @This();

origin: Point,
dir: vec3.Vec3,

pub fn at(self: Self, t: f64) Point {
    return self.origin + vec3.fill(t) * self.dir;
}
