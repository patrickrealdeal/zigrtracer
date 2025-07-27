const std = @import("std");
const vec3 = @import("vector3.zig");
const color = @import("color.zig");
const Ray = @import("ray.zig");
const HittableList = @import("hittable.zig").HittableList;
const HitRecord = @import("hittable.zig").HitRecord;
const random = @import("utility.zig");
const Random = random.Random;
const Progress = std.Progress;
const Writer = std.Io.Writer;

const Vec3 = vec3.Vec3;
const Point = vec3.Point;
//const Color = color.Color;

pub const aspect_ratio = 16.0 / 9.0;
pub const img_width = 500;
pub const samples_per_pixel = 200;
const max_depth = 10;

const img_height = blk: {
    const h: comptime_int = @intFromFloat((img_width - 0.0) / aspect_ratio);
    if (h < 1) break :blk 1;
    break :blk h;
};

const focal_length = 1.0;
const viewport_height = 2.0;
const viewport_width = viewport_height * (img_width + 0.0) / (img_height - 0.0);
const camera_center: Vec3 = vec3.zero;

// Calculate the vectors across the horizontal and down the vertical viewport edges
const viewport_u: Vec3 = .{ viewport_width, 0, 0 };
const viewport_v: Vec3 = .{ 0, -viewport_height, 0 };

// Calculate the horizontal and vertical delta vectors from pixel to pixel.
const pixel_delta_u: Vec3 = viewport_u / vec3.splat(img_width);
const pixel_delta_v: Vec3 = viewport_v / vec3.splat(img_height);

// Calculate the location of the upper left pixel.
const viewport_upper_left: Vec3 = blk: {
    const vu_half = viewport_u / vec3.splat(2);
    const vv_half = viewport_v / vec3.splat(2);
    const focal3: Vec3 = .{ 0, 0, focal_length };
    break :blk camera_center - focal3 - vu_half - vv_half;
};
const pixel00_loc = viewport_upper_left +
    (vec3.splat(0.5) * (pixel_delta_u + pixel_delta_v));

pub fn render(out: *Writer, world: *HittableList) !void {
    // Render
    var pbuf: [1024]u8 = undefined;
    const pr = Progress.start(.{
        .draw_buffer = &pbuf,
        .estimated_total_items = img_height,
        .root_name = "raytracing",
    });
    defer pr.end();

    const gpa = std.heap.smp_allocator;

    var out_buf: [][3]u8 = try gpa.alloc([3]u8, img_width * img_height);
    var pool: std.Thread.Pool = undefined;
    try pool.init(.{ .allocator = gpa });

    var wg: std.Thread.WaitGroup = .{};

    try out.print("P6\n{d} {d}\n255\n", .{ img_width, img_height });

    for (0..img_height) |y| {
        pool.spawnWg(&wg, computeRow, .{
            y,
            out_buf[y * img_width ..][0..img_width],
            world,
            pr,
        });
    }
    pool.waitAndWork(&wg);

    try out.writeSliceEndian(u8, std.mem.sliceAsBytes(out_buf), .little);
    try out.flush();
}

fn computeRow(h: usize, out: [][3]u8, world: *HittableList, pr: Progress.Node) void {
    defer pr.completeOne();

    for (0..img_width) |w| {
        var pixel_color = Vec3{ 0, 0, 0 };
        for (0..samples_per_pixel) |_| {
            const r = getRay(@floatFromInt(w), @floatFromInt(h));
            pixel_color += rayColor(&r, max_depth, world);
        }
        pixel_color /= vec3.splat(samples_per_pixel);

        const x: u8 = @intFromFloat(vec3.toGamma(pixel_color[0]) * 255.999);
        const y: u8 = @intFromFloat(vec3.toGamma(pixel_color[1]) * 255.999);
        const z: u8 = @intFromFloat(vec3.toGamma(pixel_color[2]) * 255.999);
        out[w] = .{ x, y, z };
    }
}

var rand_state = std.Random.DefaultPrng.init(42);
pub const rand = rand_state.random();

fn sampleSquare() Vec3 {
    return .{
        rand.float(f64) - 0.5,
        rand.float(f64) - 0.5,
        0,
    };
}

fn getRay(w: f64, h: f64) Ray {
    @setFloatMode(.optimized);
    const offset = sampleSquare();
    const pixel_sample = pixel00_loc +
        (vec3.splat(w + (offset[0])) * pixel_delta_u) +
        (vec3.splat(h + (offset[1])) * pixel_delta_v);
    // const pixel_sample: Vec3 = @mulAdd(
    //     Vec3,
    //     vec.splat(h + offset[1]),
    //     pixel_delta_v,
    //     @mulAdd(
    //         Vec3,
    //         vec.splat(w + offset[0]),
    //         pixel_delta_u,
    //         pixel00_loc,
    //     ),
    // );

    const ray_direction = pixel_sample - camera_center;
    return Ray{ .origin = camera_center, .dir = ray_direction };
}

fn sampleSquared(prng: *Random.DefaultPrng) Vec3 {
    const rng = prng.random();
    return Vec3{ random.genRand(rng, f64) - 0.5, random.genRand(rng, f64) - 0.5, 0 };
}

fn rayColor(r: *const Ray, depth: u8, world: *HittableList) Vec3 {
    // If we exceed the ray bounce limit, no more light is gathered
    if (depth <= 0) {
        return .{ 0, 0, 0 };
    }

    const hit_res = world.hit(r, 0.001, std.math.floatMax(f64));
    if (hit_res.is_hit) {
        var rec: HitRecord = hit_res.rec.?;
        var ray_scattered: Ray = undefined;
        var attenuation: Vec3 = undefined;

        if (rec.mat.scatter(r, &rec, &attenuation, &ray_scattered)) {
            return attenuation * rayColor(&ray_scattered, depth - 1, world);
        } else {
            return Vec3{ 0, 0, 0 };
        }
    }

    const unit_direction = vec3.unit(r.dir);
    const a = 0.5 * (unit_direction[1] + 1.0);
    return (vec3.splat(1.0 - a) * Vec3{ 1, 1, 1 }) + (vec3.splat(a) * Vec3{ 0.5, 0.7, 1.0 });
}
