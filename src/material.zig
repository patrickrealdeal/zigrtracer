const std = @import("std");
const Ray = @import("ray.zig");
const HitRecord = @import("hittable.zig").HitRecord;
const Camera = @import("camera.zig").Camera;
const vec3 = @import("vector3.zig");
const Color = @import("color.zig").Color;

pub const Material = union(enum) {
    lambertian: Lambertian,
    metal: Metal,
    dielectric: Dielectric,

    pub fn scatter(self: *const Material, cam: *Camera, r_in: *const Ray, rec: *HitRecord, attenuation: *Color, scattered: *Ray) bool {
        return switch (self.*) {
            .lambertian => |*l| l.scatter(cam, r_in, rec, attenuation, scattered),
            .metal => |*m| m.scatter(cam, r_in, rec, attenuation, scattered),
            .dielectric => |*d| d.scatter(cam, r_in, rec, attenuation, scattered),
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
    fuzz: f64,

    pub fn scatter(self: *const Metal, cam: *Camera, r_in: *const Ray, rec: *HitRecord, attenuation: *Color, scattered: *Ray) bool {
        var reflected = vec3.reflect(r_in.dir, rec.normal);
        reflected = vec3.unit(reflected) + (vec3.splat(self.fuzz) * vec3.randomUnit(&cam.prng));
        scattered.* = Ray{ .origin = rec.p, .dir = reflected };
        attenuation.* = self.albedo;
        return (vec3.dot(scattered.dir, rec.normal) > 0);
    }
};

pub const Dielectric = struct {
    // NOTE: Refractive index in vacuum or air,
    // or the ratio of the material's refractive index over
    // the refractive index of the enclosing media
    refraction_index: f64,

    pub fn scatter(self: *const Dielectric, cam: *Camera, r_in: *const Ray, rec: *HitRecord, attenuation: *Color, scattered: *Ray) bool {
        attenuation.* = Color{ 1.0, 1.0, 1.0 };
        const ri = if (rec.front_face) (1.0 / self.refraction_index) else self.refraction_index;

        const unit_direction = vec3.unit(r_in.dir);
        const cos_theta = @min(vec3.dot(-unit_direction, rec.normal), 1.0);
        const sin_theta = @sqrt(1.0 - cos_theta * cos_theta);

        const cannot_refract = ri * sin_theta > 1.0;
        var direction: vec3.Vec3 = undefined;

        if (cannot_refract or reflectance(cos_theta, ri) > cam.prng.random().float(f64)) {
            direction = vec3.reflect(unit_direction, rec.normal);
        } else {
            direction = vec3.refract(unit_direction, rec.normal, ri);
        }

        scattered.* = Ray{ .origin = rec.p, .dir = direction };
        return true;
    }

    fn reflectance(cosine: f64, refraction_index: f64) f64 {
        // Use Schlick's approximation for reflectance.
        var r0 = (1 - refraction_index) / (1 + refraction_index);
        r0 = r0 * r0;
        return r0 + (1 - r0) * std.math.pow(f64, 1 - cosine, 5);
    }
};
