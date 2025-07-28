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

pub fn main() !void {
    var dba: std.heap.DebugAllocator(.{}) = .init;
    const allocator = dba.allocator();
    defer _ = dba.deinit();

    var wbuf: [4096]u8 = undefined;
    var file_writer = std.fs.File.stdout().writer(&wbuf);
    const out = &file_writer.interface;

    // World
    var world: HittableList = .init(allocator);
    defer world.deinit();

    var allocated_materials = std.ArrayList(*mat.Material).init(dba.allocator());
    defer {
        for (allocated_materials.items) |item| {
            dba.allocator().destroy(item);
        }
        allocated_materials.deinit();
    }

    for (0..22) |a| {
        const x = @as(f64, @floatFromInt(a)) - 11;
        for (0..22) |b| {
            const y = @as(f64, @floatFromInt(b)) - 11;
            const chose_mat = camera.rand.float(f64);
            const center = Vec3{ x + 0.9 * camera.rand.float(f64), 0.2, y + 0.9 * camera.rand.float(f64) };

            if (vec3.magnitude(center - Vec3{ 4, 0.2, 0 }) > 0.9) {
                const sphere_material = try dba.allocator().create(mat.Material);
                if (chose_mat < 0.8) {
                    // Diffuse
                    const albedo = vec3.random(camera.rand) * vec3.random(camera.rand);
                    sphere_material.* = .{ .lambertian = .{ .albedo = albedo } };
                } else if (chose_mat < 0.95) {
                    // Metal
                    const albedo = vec3.randomRange(camera.rand, 0.5, 1);
                    const fuzz = camera.rand.float(f64);
                    sphere_material.* = .{ .metal = .{ .albedo = albedo, .fuzz = fuzz } };
                } else {
                    // Dielectric
                    sphere_material.* = .{ .dielectric = .{ .refraction_index = 1.5 } };
                }

                try allocated_materials.append(sphere_material);
                try world.add(Hittable{ .sphere = .init(center, 0.2, sphere_material) });
            }
        }
    }

    var ground_material = mat.Material{ .lambertian = .{ .albedo = .{ 0.5, 0.5, 0.5 } } };
    var material1 = mat.Material{ .dielectric = .{ .refraction_index = 1.50 } };
    var material2 = mat.Material{ .lambertian = .{ .albedo = Vec3{ 0.4, 0.2, 0.1 } } };
    var material3 = mat.Material{ .metal = .{ .albedo = .{ 0.7, 0.6, 0.5 }, .fuzz = 0.0 } };

    const sphere0 = Hittable{ .sphere = .init(Point{ 0, -1000, 0 }, 1000, &ground_material) }; // Ground
    const sphere1 = Hittable{ .sphere = .init(Point{ 0, 1.0, 0.0 }, 1.0, &material1) };
    const sphere2 = Hittable{ .sphere = .init(Point{ -4.0, 1.0, 0.0 }, 1.0, &material2) };
    const sphere3 = Hittable{ .sphere = .init(Point{ 4, 1, 0.0 }, 1.0, &material3) };

    try world.add(sphere0);
    try world.add(sphere1);
    try world.add(sphere2);
    try world.add(sphere3);

    try camera.render(out, &world);
}
