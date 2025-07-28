const std = @import("std");
const vec3 = @import("vector3.zig");
const Ray = @import("ray.zig");
const Material = @import("material.zig").Material;

const Allocator = std.mem.Allocator;
const Point = vec3.Point;
const Vec3 = vec3.Vec3;

const HitResult = struct {
    is_hit: bool,
    rec: ?HitRecord,
};

pub const HitRecord = struct {
    p: Point, // Point where Ray hits
    normal: Vec3, // Orientation of the surface at p
    t: f64,
    front_face: bool,
    mat: *Material,

    fn set_face_normal(self: *HitRecord, r: *const Ray, outward_normal: *Vec3) void {
        // Set the hit_record normal vector
        // NOTE: the parameter outward_normal is assumed to be unit length
        self.front_face = vec3.dot(r.dir, outward_normal.*) < 0;
        self.normal = if (self.front_face) outward_normal.* else -outward_normal.*;
    }
};

pub const Hittable = union(enum) {
    sphere: Sphere,

    pub fn hit(self: *Hittable, r: *const Ray, r_tmin: f64, r_tmax: f64) HitResult {
        return switch (self.*) {
            .sphere => |*s| s.hit(r, r_tmin, r_tmax),
        };
    }
};

pub const HittableList = struct {
    objects: std.ArrayList(Hittable),
    allocator: Allocator,

    pub fn init(allocator: Allocator) HittableList {
        return .{ .objects = std.ArrayList(Hittable).init(allocator), .allocator = allocator };
    }

    pub fn deinit(self: *HittableList) void {
        self.objects.deinit();
    }

    pub fn add(self: *HittableList, object: anytype) !void {
        try self.objects.append(object);
    }

    pub fn hit(self: *HittableList, r: *const Ray, r_tmin: f64, r_tmax: f64) HitResult {
        var rec: HitRecord = undefined;
        var hit_anything = false;
        var closest_so_far = r_tmax;

        for (self.objects.items) |*obj| {
            const temp_hit = obj.hit(r, r_tmin, closest_so_far);
            const temp_rec = temp_hit.rec;
            if (temp_hit.is_hit) {
                hit_anything = true;
                closest_so_far = temp_rec.?.t;
                rec = temp_rec.?;
            }
        }

        return .{ .is_hit = hit_anything, .rec = rec };
    }
};

pub const Sphere = struct {
    center: Point,
    radius: f64,
    mat: *Material,

    pub fn init(center: Point, radius: f64, mat: *Material) Sphere {
        std.debug.assert(radius > 0);
        return .{ .center = center, .radius = radius, .mat = mat };
    }

    pub fn hit(self: *Sphere, r: *const Ray, r_tmin: f64, r_tmax: f64) HitResult {
        var rec: HitRecord = undefined;
        // NOTE: sphere math
        const oc = self.center - r.origin;
        const a = vec3.magnitude2(r.dir);
        const h = vec3.dot(r.dir, oc);
        const c = vec3.magnitude2(oc) - self.radius * self.radius;

        const discriminant = h * h - a * c;
        if (discriminant < 0) {
            return .{ .is_hit = false, .rec = null };
        }
        const sqrtd = @sqrt(discriminant);

        // Find the nearest root that lies in the acceptable range
        var root = (h - sqrtd) / a; // the minus solution  --(t)---->
        if (root <= r_tmin or r_tmax <= root) {
            root = (h + sqrtd) / a; // the plus solution   -------(t)->
            if (root <= r_tmin or r_tmax <= root) {
                return .{ .is_hit = false, .rec = rec };
            }
        }

        rec.t = root;
        rec.p = r.at(rec.t);
        var outward_normal = (rec.p - self.center) / vec3.splat(self.radius);
        rec.set_face_normal(r, &outward_normal);
        rec.mat = self.mat;

        return .{ .is_hit = true, .rec = rec };
    }
};
