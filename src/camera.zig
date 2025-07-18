const std = @import("std");
const vec3 = @import("vector3.zig");
const color = @import("color.zig");
const Ray = @import("ray.zig");
const HittableList = @import("hittable.zig").HittableList;
const HitRecord = @import("hittable.zig").HitRecord;
const random = @import("utility.zig");
const Random = random.Random;

const Vec3 = vec3.Vec3;
const Point = vec3.Point;
const Color = color.Color;

const stdout = std.io.getStdOut().writer();
const stderr = std.io.getStdErr().writer();

pub const Camera = struct {
    image_height: u32,
    image_width: usize,
    center: Point,
    pixel00_loc: Point,
    pixel_delta_u: Vec3,
    pixel_delta_v: Vec3,
    samples_per_pixel: u32 = 100,
    pixel_samples_scale: f64,
    prng: Random.DefaultPrng,

    pub fn init() Camera {
        // Image
        const aspect_ratio: f64 = 16.0 / 9.0;
        const image_width = 400;
        const samples_per_pixel: u32 = 100;
        const pixel_samples_scale: f64 = 1.0 / @as(f64, @floatFromInt(samples_per_pixel));
        const prng = Random.DefaultPrng.init(@intCast(std.time.nanoTimestamp()));

        // calculate image height and ensure that its at least 1
        var image_height: u32 = @as(u32, @intFromFloat(image_width / aspect_ratio));
        if (image_height < 1) {
            image_height = 1;
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
        const pixel_delta_u = viewport_u / vec3.fill(image_width);
        const pixel_delta_v = viewport_v / vec3.fill(image_height);

        // calculate the location of the upper left pixel
        const viewport_upper_left = camera_center - Vec3{ 0, 0, focal_length } - viewport_u / vec3.fill(2.0) - viewport_v / vec3.fill(2.0);
        const pixel00_loc = viewport_upper_left + vec3.fill(0.5) * (pixel_delta_u + pixel_delta_v);

        return Camera{
            .image_height = image_height,
            .image_width = image_width,
            .center = camera_center,
            .pixel00_loc = pixel00_loc,
            .pixel_delta_u = pixel_delta_u,
            .pixel_delta_v = pixel_delta_v,
            .samples_per_pixel = samples_per_pixel,
            .pixel_samples_scale = pixel_samples_scale,
            .prng = prng,
        };
    }

    pub fn render(self: *Camera, world: *HittableList) !void {
        // Render
        try stdout.print("P3\n{d} {d}\n255\n", .{ self.image_width, self.image_height });

        for (0..self.image_height) |y| {
            try stderr.print("\rScanlines remaninig: {d:<5}", .{(self.image_height - y - 1)});
            for (0..self.image_width) |x| {
                var pixel_color = Color{ 0, 0, 0 };
                for (0..self.samples_per_pixel) |_| {
                    const r = self.getRay(@floatFromInt(x), @floatFromInt(y));
                    pixel_color += rayColor(self, &r, world);
                }
                pixel_color *= vec3.fill(self.pixel_samples_scale);
                try color.write_color(stdout, &pixel_color);
            }
        }
        try stderr.print("\rDone.", .{});
    }

    fn getRay(self: *Camera, x: f64, y: f64) Ray {
        // Construct a camera ray originating from the origin and directed at randomly sampled
        // point around the pixel location i, j.
        const offset = sampleSquared(&self.prng);
        const pixel_sample = self.pixel00_loc + ((vec3.fill(x + offset[0])) * self.pixel_delta_u) + ((vec3.fill(y + offset[1])) * self.pixel_delta_v);
        const ray_origin = self.center;
        const ray_direction = pixel_sample - ray_origin;
        return Ray{ .origin = ray_origin, .dir = ray_direction };
    }

    fn sampleSquared(prng: *Random.DefaultPrng) Vec3 {
        const rng = prng.random();
        return Vec3{ random.genRand(rng, f64) - 0.5, random.genRand(rng, f64) - 0.5, 0 };
    }

    fn rayColor(self: *Camera, r: *const Ray, world: *HittableList) Color {
        var rec: HitRecord = undefined;

        if (world.hit(r, 0, std.math.floatMax(f64), &rec)) {
            const direction = vec3.randomOnHemisphere(&self.prng, &rec.normal);
            const ray = Ray{ .origin = rec.p, .dir = direction };
            return vec3.fill(0.5) * rayColor(self, &ray, world);
        }

        const unit_direction = vec3.unit(r.dir);
        const a = 0.5 * (unit_direction[1] + 1.0);
        return (vec3.fill(1.0 - a) * Color{ 1, 1, 1 }) + (vec3.fill(a) * Color{ 0.5, 0.7, 1.0 });
    }
};
