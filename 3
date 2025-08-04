const std = @import("std");
const vec3 = @import("vector3.zig");
const Material = @import("material.zig").Material;
const Ray = @import("ray.zig");
const Sphere = @import("hittable.zig").Sphere;
const HitRecord = @import("hittable.zig").HitRecord;
const Hittable = @import("hittable.zig").Hittable;
const hittable = @import("hittable.zig");
const HittableList = @import("hittable.zig").HittableList;
const BhvNode = @import("hittable.zig").BhvNode;
const camera = @import("camera.zig");
const Allocator = std.mem.Allocator;
const Progress = std.Progress;

const Vec3 = vec3.Vec3;
const Point = vec3.Point;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
    //defer arena.deinit();
    const allocator = arena.allocator();

    var wbuf: [4096]u8 = undefined;
    var file_writer = std.fs.File.stdout().writer(&wbuf);
    const out = &file_writer.interface;

    // World
    var list: HittableList = .init();
    defer list.deinit(allocator);

    const rand = camera.rand_state.random();

    for (0..22) |x| {
        const a = @as(f64, @floatFromInt(x)) - 11;
        for (0..22) |y| {
            const b = @as(f64, @floatFromInt(y)) - 11;
            const chose_mat = rand.float(f64);
            const center = Vec3{ a + 0.9 * rand.float(f64), 0.2, b + 0.9 * rand.float(f64) };

            if (vec3.magnitude(center - Vec3{ 4, 0.2, 0 }) > 0.9) {
                var sphere_material: Material = undefined;
                if (chose_mat < 0.8) {
                    // Diffuse
                    const center2 = center + Vec3{ 0, rand.float(f64), 0 };
                    sphere_material = .{ .lambertian = .{ .albedo = vec3.random(rand) * vec3.random(rand) } };
                    try list.add(allocator, Hittable{ .sphere = .initMoving(center, center2, 0.2, sphere_material) });
                } else if (chose_mat < 0.95) {
                    // Metal
                    sphere_material = .{ .metal = .{ .albedo = vec3.randomRange(rand, 0.5, 1), .fuzz = rand.float(f64) } };
                    try list.add(allocator, Hittable{ .sphere = .init(center, 0.2, sphere_material) });
                } else {
                    // Dielectric
                    sphere_material = .{ .dielectric = .{ .refraction_index = 1.5 } };
                    try list.add(allocator, Hittable{ .sphere = .init(center, 0.2, sphere_material) });
                }
            }
        }
    }

    const ground_material = Material{ .lambertian = .{ .albedo = .{
        std.math.pow(f64, 184.0 / 255.0, 2),
        std.math.pow(f64, 184.0 / 255.0, 2),
        std.math.pow(f64, 255.0 / 255.0, 2),
    } } };
    const material1 = Material{ .dielectric = .{ .refraction_index = 1.50 } };
    const material2 = Material{ .lambertian = .{ .albedo = .{ 0.4, 0.2, 0.1 } } };
    const material3 = Material{ .metal = .{ .albedo = .{ 0.7, 0.6, 0.5 }, .fuzz = 0.0 } };

    const sphere0 = Hittable{ .sphere = .init(.{ 0, -1000, 0 }, 1000, ground_material) }; // Ground
    const sphere1 = Hittable{ .sphere = .init(.{ 0, 1.0, 0.0 }, 1.0, material1) };
    const sphere2 = Hittable{ .sphere = .init(.{ -4.0, 1.0, 0.0 }, 1.0, material2) };
    const sphere3 = Hittable{ .sphere = .init(.{ 4, 1, 0.0 }, 1.0, material3) };

    try list.add(allocator, sphere0);
    try list.add(allocator, sphere1);
    try list.add(allocator, sphere2);
    try list.add(allocator, sphere3);

    // try renderSceneOne(allocator, rand, &world);
    var hittable_pointers = std.ArrayList(*Hittable).init(allocator);
    defer hittable_pointers.deinit();
    for (list.objects.items) |*obj| {
        try hittable_pointers.append(obj);
    }

    const world_tree = try BhvNode.init(allocator, hittable_pointers.items);
    var world: Hittable = .{ .bhv_node = world_tree };
    try camera.render(out, &world);
}

fn renderSceneOne(allocator: Allocator, rand: std.Random, world: *HittableList) !void {
    for (0..22) |x| {
        const a = @as(f64, @floatFromInt(x)) - 11;
        for (0..22) |y| {
            const b = @as(f64, @floatFromInt(y)) - 11;
            const chose_mat = rand.float(f64);
            const center = Vec3{ a + 0.9 * rand.float(f64), 0.2, b + 0.9 * rand.float(f64) };

            if (vec3.magnitude(center - Vec3{ 4, 0.2, 0 }) > 0.9) {
                const sphere_material: Material = if (chose_mat < 0.8)
                    // Diffuse
                    .{ .lambertian = .{ .albedo = vec3.random(rand) * vec3.random(rand) } }
                else if (chose_mat < 0.95)
                    // Metal
                    .{ .metal = .{ .albedo = vec3.randomRange(rand, 0.5, 1), .fuzz = rand.float(f64) } }
                else
                    // Dielectric
                    .{ .dielectric = .{ .refraction_index = 1.5 } };

                try world.add(allocator, Hittable{ .sphere = .init(center, 0.2, sphere_material) });
            }
        }
    }

    const ground_material = Material{ .lambertian = .{ .albedo = .{
        std.math.pow(f64, 184.0 / 255.0, 2),
        std.math.pow(f64, 184.0 / 255.0, 2),
        std.math.pow(f64, 255.0 / 255.0, 2),
    } } };
    const material1 = Material{ .dielectric = .{ .refraction_index = 1.50 } };
    const material2 = Material{ .lambertian = .{ .albedo = .{ 0.4, 0.2, 0.1 } } };
    const material3 = Material{ .metal = .{ .albedo = .{ 0.7, 0.6, 0.5 }, .fuzz = 0.0 } };

    const sphere0 = Hittable{ .sphere = .init(.{ 0, -1000, 0 }, 1000, ground_material) }; // Ground
    const sphere1 = Hittable{ .sphere = .init(.{ 0, 1.0, 0.0 }, 1.0, material1) };
    const sphere2 = Hittable{ .sphere = .init(.{ -4.0, 1.0, 0.0 }, 1.0, material2) };
    const sphere3 = Hittable{ .sphere = .init(.{ 4, 1, 0.0 }, 1.0, material3) };

    try world.add(allocator, sphere0);
    try world.add(allocator, sphere1);
    try world.add(allocator, sphere2);
    try world.add(allocator, sphere3);
}
