const std = @import("std");
const color = @import("color.zig");
const vec3 = @import("vector3.zig");
const Ray = @import("ray.zig");
const Sphere = @import("hittable.zig").Sphere;
const HitRecord = @import("hittable.zig").HitRecord;
const Hittable = @import("hittable.zig").Hittable;
const HittableList = @import("hittable.zig").HittableList;
const Camera = @import("camera.zig").Camera;

const Vec3 = vec3.Vec3;
const Point = vec3.Point;
const Color = color.Color;

const stdout = std.io.getStdOut().writer();
const stderr = std.io.getStdErr().writer();

pub fn main() !void {
    var dba: std.heap.DebugAllocator(.{}) = .init;
    const allocator = dba.allocator();
    defer _ = dba.deinit();

    // World
    var world: HittableList = .init(allocator);
    defer world.deinit();

    const sphere0 = Hittable{ .sphere = .{ .center = Point{ 0, 0, -1 }, .radius = 0.5 } };
    const sphere1 = Hittable{ .sphere = .{ .center = Point{ 0, -100.5, -1 }, .radius = 100 } };
    try world.add(sphere0);
    try world.add(sphere1);

    var camera: Camera = .init();
    try camera.render(&world);
}
