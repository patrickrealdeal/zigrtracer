const std = @import("std");
const vec3 = @import("vector3.zig");
const Ray = @import("ray.zig");
const Material = @import("material.zig").Material;

const Allocator = std.mem.Allocator;
const Point = vec3.Point;
const Vec3 = vec3.Vec3;
const inf64 = std.math.inf(f64);

const HitResult = struct {
    is_hit: bool,
    rec: HitRecord,
};

pub const HitRecord = struct {
    p: Point, // Point where Ray hits
    normal: Vec3, // Orientation of the surface at p
    t: f64,
    front_face: bool,
    mat: Material,

    fn set_face_normal(self: *HitRecord, r: *const Ray, outward_normal: *Vec3) void {
        // Set the hit_record normal vector
        // NOTE: the parameter outward_normal is assumed to be unit length
        self.front_face = vec3.dot(r.dir, outward_normal.*) < 0;
        self.normal = if (self.front_face) outward_normal.* else -outward_normal.*;
    }
};

pub const Hittable = union(enum) {
    sphere: Sphere,

    pub fn hit(self: *Hittable, r: *const Ray, interval: Interval) ?HitResult {
        return switch (self.*) {
            .sphere => |*s| s.hit(r, interval),
        };
    }
};

pub const HittableList = struct {
    objects: std.ArrayListUnmanaged(Hittable),

    pub fn init() HittableList {
        return .{ .objects = std.ArrayListUnmanaged(Hittable).empty };
    }

    pub fn deinit(self: *HittableList, allocator: Allocator) void {
        self.objects.deinit(allocator);
    }

    pub fn add(self: *HittableList, allocator: Allocator, object: anytype) !void {
        try self.objects.append(allocator, object);
    }

    pub fn hit(self: *HittableList, r: *const Ray, interval: Interval) ?HitResult {
        var hit_res: ?HitResult = null;
        var closest_so_far = interval.max;

        for (self.objects.items) |*obj| {
            if (obj.hit(r, .{ .min = interval.min, .max = closest_so_far })) |h| {
                hit_res = h;
                closest_so_far = hit_res.?.rec.t;
            }
        }
        return hit_res;
    }
};

pub const Interval = struct {
    min: f64,
    max: f64,

    pub const empty: Interval = .{
        .min = inf64,
        .max = -inf64,
    };
    pub const universe: Interval = .{
        .min = -inf64,
        .max = inf64,
    };

    pub fn size(i: Interval) f64 {
        return i.max - i.min;
    }

    pub fn contains(i: Interval, x: f64) bool {
        return i.min <= x and x <= i.max;
    }

    pub fn surrounds(i: Interval, x: f64) bool {
        return i.min < x and x < i.max;
    }
};

pub const Sphere = struct {
    center: Ray,
    radius: f64,
    mat: Material,

    pub fn init(center: Point, radius: f64, mat: Material) Sphere {
        std.debug.assert(radius > 0);
        return .{ .center = .{ .origin = center, .dir = vec3.zero }, .radius = radius, .mat = mat };
    }

    pub fn initMoving(center1: Point, center2: Point, radius: f64, mat: Material) Sphere {
        return .{ .center = .{ .origin = center1, .dir = center2 - center1 }, .radius = radius, .mat = mat };
    }

    pub fn hit(self: *Sphere, r: *const Ray, interval: Interval) ?HitResult {
        // NOTE: To simulate movement we move the center during rendering from t = 0 to t = 1
        const current_center = self.center.at(r.tm);
        const oc = current_center - r.origin;

        var rec: HitRecord = undefined;
        // NOTE: sphere math
        const a = vec3.magnitude2(r.dir);
        const h = vec3.dot(r.dir, oc);
        const c = vec3.magnitude2(oc) - self.radius * self.radius;

        const discriminant = h * h - a * c;
        if (discriminant < 0) {
            return null;
        }
        const sqrtd = @sqrt(discriminant);

        // Find the nearest root that lies in the acceptable range
        var root = (h - sqrtd) / a; // the minus solution  --(t)---->
        if (!interval.surrounds(root)) {
            root = (h + sqrtd) / a; // the plus solution   -------(t)->
            if (!interval.surrounds(root)) {
                return null;
            }
        }

        rec.t = root;
        rec.p = r.at(rec.t);
        var outward_normal = (rec.p - current_center) / vec3.splat(self.radius);
        rec.set_face_normal(r, &outward_normal);
        rec.mat = self.mat;

        return .{ .is_hit = true, .rec = rec };
    }
};
