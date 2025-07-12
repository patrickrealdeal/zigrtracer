const std = @import("std");
const vec3 = @import("vector3.zig");
const Ray = @import("ray.zig");

const Point = vec3.Point;
const Vec3 = vec3.Vec3;

pub const HitRecord = struct {
    p: Point, // Point where Ray hits
    normal: Vec3, // Orientation of the surface at p
    t: f64,
    front_face: bool,

    fn set_face_normal(self: *HitRecord, r: *const Ray, outward_normal: *Vec3) void {
        // Set the hit_record normal vector
        // NOTE: the parameter outward_normal is assumed to be unit length
        self.front_face = vec3.dot(r.dir, outward_normal.*) < 0;
        self.normal = if (self.front_face) outward_normal.* else -outward_normal.*;
    }
};

pub const Hittable = union(enum) {
    sphere: Sphere,

    pub fn hit(self: *Hittable, r: *const Ray, r_tmin: f64, r_tmax: f64, rec: *HitRecord) bool {
        return switch (self.*) {
            .sphere => |*s| s.hit(r, r_tmin, r_tmax, rec),
        };
    }
};

pub const Sphere = struct {
    center: Point,
    radius: f64,

    pub fn hit(self: *Sphere, r: *const Ray, r_tmin: f64, r_tmax: f64, rec: *HitRecord) bool {
        // sphere math
        const oc = self.center - r.origin;
        const a = vec3.len_squared(r.dir);
        const h = vec3.dot(r.dir, oc);
        const c = vec3.len_squared(oc) - self.radius * self.radius;

        const discriminant = h * h - a * c;
        if (discriminant < 0) {
            return false;
        }
        const sqrtd = @sqrt(discriminant);

        // Find the nearest root that lies in the acceptable range
        var root = (h - sqrtd) / a; // the minus solution  --(t)---->
        if (root <= r_tmin or r_tmax <= root) {
            root = (h + sqrtd) / a; // the plus solution   -------(t)->
            if (root <= r_tmin or r_tmax <= root) {
                return false;
            }
        }

        rec.t = root;
        rec.p = r.at(rec.t);
        var outward_normal = (rec.p - self.center) / vec3.f3(self.radius);
        rec.set_face_normal(r, &outward_normal);

        return true;
    }
};
