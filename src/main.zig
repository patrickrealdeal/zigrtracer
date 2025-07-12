const std = @import("std");
const color = @import("color.zig");
const vec3 = @import("vector3.zig");
const Ray = @import("ray.zig");
const Sphere = @import("hittable.zig").Sphere;
const HitRecord = @import("hittable.zig").HitRecord;
const Hittable = @import("hittable.zig").Hittable;

const Vec3 = vec3.Vec3;
const Point = vec3.Point;
const Color = color.Color;

const stdout = std.io.getStdOut().writer();
const stderr = std.io.getStdErr().writer();

fn ray_color(r: *const Ray) Color {
    const center = Point{ 0, 0, -1 };

    var rec: HitRecord = undefined;    
    var sphere = Hittable { .sphere = .{ .center = center, .radius = 0.5 } };

    const is_hit = sphere.hit(r, 0, std.math.floatMax(f64), &rec);
    if (is_hit) {
        const N = vec3.unit(r.at(rec.t) - Vec3{ 0, 0, -1 });
        return vec3.f3(0.5) * Color{ N[0] + 1, N[1] + 1, N[2] + 1 };
    }

    const unit_direction = vec3.unit(r.dir);
    const a = 0.5 * (unit_direction[1] + 1.0);
    return (vec3.f3(1.0 - a) * Color{ 1, 1, 1 }) + (vec3.f3(a) * Color{ 0.5, 0.7, 1.0 });
}

pub fn main() !void {
    // Image
    const aspect_ratio: f64 = 16.0 / 9.0;
    const image_width = 400;

    // calculate image height and ensure that its at least 1
    var image_height: u32 = @as(u32, @intFromFloat(image_width / aspect_ratio));
    if (image_height < 1) {
        image_height = 1;
    } else {
        image_height = image_height;
    }

    // Camera
    const focal_length = 1.0;
    const viewport_height = 2.0;
    const viewport_width = viewport_height * aspect_ratio;
    const camera_center = Point{ 0, 0, 0 };

    // calcualate vectors across horizontal and vertical viewport edges
    const viewport_u = Vec3{ viewport_width, 0, 0 };
    const viewport_v = Vec3{ 0, -viewport_height, 0 };

    // calcualte the horizontal and verical delta vectors from pixel to pixel
    const pixel_delta_u = viewport_u / vec3.f3(image_width);
    const pixel_delta_v = viewport_v / vec3.f3(image_height);

    // calculate the location of the upper left pixel
    const viewport_upper_left = camera_center - Vec3{ 0, 0, focal_length } - viewport_u / vec3.f3(2.0) - viewport_v / vec3.f3(2.0);
    const pixel00_loc = viewport_upper_left + vec3.f3(0.5) * (pixel_delta_u + pixel_delta_v);

    // Render
    try stdout.print("P3\n{d} {d}\n255\n", .{ image_width, image_height });

    for (0..image_height) |y| {
        try stderr.print("\rScanlines remaninig: {d}", .{(image_height - y)});
        for (0..image_width) |x| {
            const pixel_center = pixel00_loc + (vec3.f3(x) * pixel_delta_u) + (vec3.f3(y) * pixel_delta_v);
            const ray_direction = pixel_center - camera_center;
            const r = Ray{ .origin = camera_center, .dir = ray_direction };

            var pixel_color = ray_color(&r);
            try color.write_color(stdout, &pixel_color);
        }
    }
    try stderr.print("\rDone.", .{});
}
