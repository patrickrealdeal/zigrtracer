const std = @import("std");
const vec3 = @import("vector3.zig");
const color = @import("color.zig");
const Ray = @import("ray.zig");
const HittableList = @import("hittable.zig").HittableList;
const HitRecord = @import("hittable.zig").HitRecord;

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


    pub fn init() Camera {
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
        const pixel_delta_u = viewport_u / vec3.fill(image_width);
        const pixel_delta_v = viewport_v / vec3.fill(image_height);

        // calculate the location of the upper left pixel
        const viewport_upper_left = camera_center - Vec3{ 0, 0, focal_length } - viewport_u / vec3.fill(2.0) - viewport_v / vec3.fill(2.0);
        const pixel00_loc = viewport_upper_left + vec3.fill(0.5) * (pixel_delta_u + pixel_delta_v);        
    
        return Camera {
            .image_height = image_height,
            .image_width = image_width,
            .center = camera_center,
            .pixel00_loc = pixel00_loc,
            .pixel_delta_u = pixel_delta_u,
            .pixel_delta_v = pixel_delta_v,
        };
    }

    pub fn render(self: *Camera, world: *HittableList) !void {
         // Render
        try stdout.print("P3\n{d} {d}\n255\n", .{ self.image_width, self.image_height });

        for (0..self.image_height) |y| {
            try stderr.print("\rScanlines remaninig: {d}", .{(self.image_height - y)});
            for (0..self.image_width) |x| {
                const pixel_center = self.pixel00_loc + (vec3.fill(x) * self.pixel_delta_u) + (vec3.fill(y) * self.pixel_delta_v);
                const ray_direction = pixel_center - self.center;
                const r = Ray{ .origin = self.center, .dir = ray_direction };

                var pixel_color = ray_color(&r, world);
                try color.write_color(stdout, &pixel_color);
            }
        }
        try stderr.print("\rDone.", .{});

    }


    fn ray_color(r: *const Ray, world: *HittableList) Color {
        var rec: HitRecord = undefined;

        if (world.hit(r, 0, std.math.floatMax(f64), &rec)) {
            return vec3.fill(0.5) * (rec.normal + Color{ 1, 1, 1 });
        }

        const unit_direction = vec3.unit(r.dir);
        const a = 0.5 * (unit_direction[1] + 1.0);
        return (vec3.fill(1.0 - a) * Color{ 1, 1, 1 }) + (vec3.fill(a) * Color{ 0.5, 0.7, 1.0 });
    }
   
};
