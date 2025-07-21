const std = @import("std");
const color = @import("color.zig");
const vec3 = @import("vector3.zig");
const mat = @import("material.zig");
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

    const material_ground = mat.Lambertian{ .albedo = Color{ 0.8, 0.8, 0.0 } };
    const material_center = mat.Lambertian{ .albedo = Color{ 0.1, 0.2, 0.5 } };
    const material_left = mat.Metal{ .albedo = Color{ 0.8, 0.8, 0.8 } };
    const material_right = mat.Metal{ .albedo = Color{ 0.8, 0.6, 0.2 } };

    const sphere0 = Hittable{ .sphere = .{ .center = Point{ 0, -100.5, -1 }, .radius = 100.0, .mat = &mat.Material{ .lambertian = material_ground } } };
    const sphere1 = Hittable{ .sphere = .{ .center = Point{ 0, 0.0, -1.2 }, .radius = 0.5, .mat = &mat.Material{ .lambertian = material_center } } };
    const sphere2 = Hittable{ .sphere = .{ .center = Point{ -1.0, 0.0, -1.0 }, .radius = 0.5, .mat = &mat.Material{ .metal = material_left } } };
    const sphere3 = Hittable{ .sphere = .{ .center = Point{ 1.0, 0.0, -1.0 }, .radius = 0.5, .mat = &mat.Material{ .metal = material_right } } };
    try world.add(sphere0);
    try world.add(sphere1);
    try world.add(sphere2);
    try world.add(sphere3);

    var camera: Camera = .init();
    try camera.render(&world);
}
