const std = @import("std");
const color = @import("color.zig");
const vec3 = @import("vector3.zig");
const mat = @import("material.zig");
const Ray = @import("ray.zig");
const Sphere = @import("hittable.zig").Sphere;
const HitRecord = @import("hittable.zig").HitRecord;
const Hittable = @import("hittable.zig").Hittable;
const HittableList = @import("hittable.zig").HittableList;
const camera = @import("camera.zig");
const Progress = std.Progress;

const Vec3 = vec3.Vec3;
const Point = vec3.Point;
const Color = color.Color;

pub fn main() !void {
    var dba: std.heap.DebugAllocator(.{}) = .init;
    const allocator = dba.allocator();
    defer _ = dba.deinit();

    // World
    var world: HittableList = .init(allocator);
    defer world.deinit();

    const material_ground = mat.Lambertian{ .albedo = Color{ 0.8, 0.8, 0.0 } };
    const material_center = mat.Lambertian{ .albedo = Color{ 0.1, 0.2, 0.5 } };
    const material_left = mat.Dielectric{ .refraction_index = 1.50 };
    const material_bubble = mat.Dielectric{ .refraction_index = 1.0 / 1.50 };
    const material_right = mat.Metal{ .albedo = Color{ 0.8, 0.6, 0.2 }, .fuzz = 1.0 };

    const sphere0 = Hittable{ .sphere = .init(Point{ 0, -100.5, -1 }, 100.0, &mat.Material{ .lambertian = material_ground }) };
    const sphere1 = Hittable{ .sphere = .init(Point{ 0, 0.0, -1.2 }, 0.5, &mat.Material{ .lambertian = material_center }) };
    const sphere2 = Hittable{ .sphere = .init(Point{ -1.0, 0.0, -1.0 }, 0.5, &mat.Material{ .dielectric = material_left }) };
    const sphere3 = Hittable{ .sphere = .init(Point{ -1.0, 0.0, -1.0 }, 0.4, &mat.Material{ .dielectric = material_bubble }) };
    const sphere4 = Hittable{ .sphere = .init(Point{ 1.0, 0.0, -1.0 }, 0.5, &mat.Material{ .metal = material_right }) };

    try world.add(sphere0);
    try world.add(sphere1);
    try world.add(sphere2);
    try world.add(sphere3);
    try world.add(sphere4);

    var wbuf: [4096]u8 = undefined;
    var file_writer = std.fs.File.stdout().writer(&wbuf);
    const out = &file_writer.interface;

    try camera.render(out, &world);
}
