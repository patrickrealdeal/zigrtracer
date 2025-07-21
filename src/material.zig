const std = @import("std");
const Ray = @import("ray.zig");
const HitRecord = @import("hittable.zig").HitRecord;
const Camera = @import("camera.zig").Camera;
const vec3 = @import("vector3.zig");
const Color = @import("color.zig").Color;

pub const Material = union(enum) {
    lambertian: Lambertian,
    metal: Metal,

    pub fn scatter(self: *const Material, cam: *Camera, r_in: *const Ray, rec: *HitRecord, attenuation: *Color, scattered: *Ray) bool {
        return switch (self.*) {
            .lambertian => |*l| l.scatter(cam, r_in, rec, attenuation, scattered),
            .metal => |*m| m.scatter(cam, r_in, rec, attenuation, scattered),
        };
    }
};

pub const Lambertian = struct {
    albedo: Color,

    pub fn scatter(self: *const Lambertian, cam: *Camera, r_in: *const Ray, rec: *HitRecord, attenuation: *Color, scattered: *Ray) bool {
        _ = r_in;
        var scattered_direction = rec.normal + vec3.randomUnit(&cam.prng);

        // Catch degenerate scatter direction
        if (vec3.nearZero(scattered_direction)) {
            scattered_direction = rec.normal;
        }

        scattered.* = Ray{ .origin = rec.p, .dir = scattered_direction };
        attenuation.* = self.albedo;
        return true;
    }
};

pub const Metal = struct {
    albedo: Color,

    pub fn scatter(self: *const Metal, cam: *Camera, r_in: *const Ray, rec: *HitRecord, attenuation: *Color, scattered: *Ray) bool {
        _ = cam;
        const reflected = vec3.reflect(r_in.dir, rec.normal);
        scattered.* = Ray{ .origin = rec.p, .dir = reflected };
        attenuation.* = self.albedo;
        return true;
    }
};
