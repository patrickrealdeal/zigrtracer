const std = @import("std");
const vec3 = @import("vector3.zig");
const Ray = @import("ray.zig");
const Material = @import("material.zig").Material;
const camera = @import("camera.zig");

const Allocator = std.mem.Allocator;
const Point = vec3.Point;
const Vec3 = vec3.Vec3;
const inf64 = std.math.inf(f64);

pub const HitResult = struct {
    is_hit: bool,
    rec: HitRecord = .empty,
};

pub const HitRecord = struct {
    p: Point, // Point where Ray hits
    normal: Vec3, // Orientation of the surface at p
    t: f64,
    front_face: bool,
    mat: Material,

    pub const empty: HitRecord = .{
        .p = vec3.zero,
        .normal = vec3.zero,
        .t = 0,
        .front_face = false,
        .mat = .{ .lambertian = .{ .albedo = vec3.zero } },
    };

    fn set_face_normal(self: *HitRecord, r: *const Ray, outward_normal: *Vec3) void {
        // Set the hit_record normal vector
        // NOTE: the parameter outward_normal is assumed to be unit length
        self.front_face = vec3.dot(r.dir, outward_normal.*) < 0;
        self.normal = if (self.front_face) outward_normal.* else -outward_normal.*;
    }
};

pub const Hittable = union(enum) {
    sphere: Sphere,
    bhv_node: *BhvNode,

    pub fn hit(self: *const Hittable, r: *const Ray, interval: Interval) ?HitResult {
        return switch (self.*) {
            .sphere => |*s| s.hit(r, interval),
            .bhv_node => |b| b.hit(r, interval),
        };
    }

    pub fn bbox(self: *const Hittable) Aabb {
        return switch (self.*) {
            .sphere => |*s| s.bbox,
            .bhv_node => |b| b.bbox,
        };
    }
};

pub const HittableList = struct {
    objects: std.ArrayListUnmanaged(Hittable),
    bbox: Aabb = .empty,

    pub fn init() HittableList {
        return .{ .objects = std.ArrayListUnmanaged(Hittable).empty };
    }

    pub fn deinit(self: *HittableList, allocator: Allocator) void {
        self.objects.deinit(allocator);
    }

    pub fn add(self: *HittableList, allocator: Allocator, object: anytype) !void {
        try self.objects.append(allocator, object);
        self.bbox = .initFromBox(self.bbox, object.bbox());
    }

    //pub fn hit(self: *HittableList, r: *const Ray, interval: Interval) ?HitResult {
    //if (!self.bbox.hit(r, interval)) {
    //return null;
    //}
    //
    //var hit_res: ?HitResult = null;
    //var closest_so_far = interval.max;
    //
    //for (self.objects.items) |*obj| {
    //if (obj.hit(r, .{ .min = interval.min, .max = closest_so_far })) |h| {
    //hit_res = h;
    //closest_so_far = hit_res.?.rec.t;
    //}
    //}
    //return hit_res;
    //}
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

    pub fn init(a: Interval, b: Interval) Interval {
        // Create the interval tightly enclosing the two input intervals.
        return .{
            .min = if (a.min <= b.min) a.min else b.min,
            .max = if (a.max >= b.max) a.max else b.max,
        };
    }

    pub fn size(i: Interval) f64 {
        return i.max - i.min;
    }

    pub fn contains(i: Interval, x: f64) bool {
        return i.min <= x and x <= i.max;
    }

    pub fn surrounds(i: Interval, x: f64) bool {
        return i.min < x and x < i.max;
    }

    pub fn expand(i: Interval, delta: f64) Interval {
        const padding = delta / 2;
        return .{ .min = i.min - padding, .max = i.max + padding };
    }
};

pub const Sphere = struct {
    center: Ray,
    radius: f64,
    mat: Material,
    bbox: Aabb = .empty,

    pub const empty: Sphere = .{
        .center = vec3.zero,
        .radius = 0,
        .mat = .{ .lambertian = .{ .albedo = vec3.zero } },
    };

    pub fn init(center: Point, radius: f64, mat: Material) Sphere {
        std.debug.assert(radius > 0);

        const rvec = Vec3{ radius, radius, radius };
        const bbox: Aabb = .init(center - rvec, center + rvec);
        return .{ .center = .{ .origin = center, .dir = vec3.zero }, .radius = @max(0, radius), .mat = mat, .bbox = bbox };
    }

    pub fn initMoving(center1: Point, center2: Point, radius: f64, mat: Material) Sphere {
        const rvec = Vec3{ radius, radius, radius };
        var sphere: Sphere = .{ .center = .{ .origin = center1, .dir = center2 - center1 }, .radius = @max(0, radius), .mat = mat };

        const box1: Aabb = .init(sphere.center.at(0) - rvec, sphere.center.at(0) + rvec);
        const box2: Aabb = .init(sphere.center.at(1) - rvec, sphere.center.at(1) + rvec);
        const bbox: Aabb = .initFromBox(box1, box2);
        sphere.bbox = bbox;

        return sphere;
    }

    pub fn hit(self: *const Sphere, r: *const Ray, interval: Interval) ?HitResult {
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

pub const BhvNode = struct {
    left: *Hittable,
    right: *Hittable,
    bbox: Aabb,

    pub fn init(allocator: Allocator, slice: []*Hittable) !*BhvNode {
        const objects = slice;
        const rand = camera.rand_state.random();
        const axis = std.Random.intRangeAtMost(rand, usize, 0, 2);

        var left_node: *Hittable = try allocator.create(Hittable);
        var right_node: *Hittable = try allocator.create(Hittable);
        var bbox: Aabb = .empty;

        if (objects.len == 1) {
            left_node = objects[0];
            right_node = left_node;
            bbox = left_node.bbox();
        } else if (objects.len == 2) {
            left_node = objects[0];
            right_node = objects[1];
            bbox = .initFromBox(left_node.bbox(), right_node.bbox());
        } else {
            // Sort the objects slice in-place
            switch (axis) {
                0 => std.sort.pdq(*Hittable, objects, {}, boxXCompare),
                1 => std.sort.pdq(*Hittable, objects, {}, boxYCompare),
                2 => std.sort.pdq(*Hittable, objects, {}, boxZCompare),
                else => unreachable,
            }

            const mid = objects.len / 2;

            const left_bhv_node_ptr = try init(allocator, objects[0..mid]);
            left_node.* = .{ .bhv_node = left_bhv_node_ptr };

            const right_bhv_node_ptr = try init(allocator, objects[mid..objects.len]);
            right_node.* = .{ .bhv_node = right_bhv_node_ptr };

            bbox = .initFromBox(left_node.bbox(), right_node.bbox());
        }

        const result = try allocator.create(BhvNode);
        result.* = BhvNode{
            .left = left_node,
            .right = right_node,
            .bbox = bbox,
        };
        return result;
    }

    pub fn hit(self: *const BhvNode, r: *const Ray, interval: Interval) ?HitResult {
        //hit_calls += 1;

        if (!self.bbox.hit(r, interval)) {
            //nodes_skipped += 1;
            return null;
        }

        var hit_res: ?HitResult = null;

        // Hit the left node first
        const hit_left = self.left.hit(r, interval);

        // Hit the right node next but only if the left hit happened or if the right bbox is closer
        const hit_right = self.right.hit(r, .{ .min = interval.min, .max = (if (hit_left) |h| h.rec.t else interval.max) });

        if (hit_left) |h| hit_res = h;
        if (hit_right) |h| hit_res = h; // The right hit is closer so we overwrite the left hit

        return hit_res;
    }

    fn boxXCompare(_: void, a: *Hittable, b: *Hittable) bool {
        return a.bbox().x.min < b.bbox().x.min;
    }
    fn boxYCompare(_: void, a: *Hittable, b: *Hittable) bool {
        return a.bbox().y.min < b.bbox().y.min;
    }
    fn boxZCompare(_: void, a: *Hittable, b: *Hittable) bool {
        return a.bbox().z.min < b.bbox().z.min;
    }
};

const Aabb = struct { // Axis aligned boudning box
    x: Interval,
    y: Interval,
    z: Interval,

    pub const empty: Aabb = .{ .x = .empty, .y = .empty, .z = .empty };

    pub fn init(a: Point, b: Point) Aabb {
        return .{
            .x = if (a[0] <= b[0]) .{ .min = a[0], .max = b[0] } else .{ .min = b[0], .max = a[0] },
            .y = if (a[1] <= b[1]) .{ .min = a[1], .max = b[1] } else .{ .min = b[1], .max = a[1] },
            .z = if (a[2] <= b[2]) .{ .min = a[2], .max = b[2] } else .{ .min = b[2], .max = a[2] },
        };
    }

    pub fn initFromBox(box0: Aabb, box1: Aabb) Aabb {
        return .{
            .x = .init(box0.x, box1.x),
            .y = .init(box0.y, box1.y),
            .z = .init(box0.z, box1.z),
        };
    }

    pub fn axisInterval(aabb: *const Aabb, n: usize) Interval {
        switch (n) {
            1 => return aabb.y,
            2 => return aabb.z,
            else => return aabb.x,
        }
    }

    pub fn hit(self: *const Aabb, r: *const Ray, interval: Interval) bool {
        var curr_interval = interval;

        for (0..3) |axis| {
            const ax = self.axisInterval(axis);

            const adinv = 1.0 / r.dir[axis];
            const t0 = (ax.min - r.origin[axis]) * adinv;
            const t1 = (ax.max - r.origin[axis]) * adinv;

            if (t0 < t1) {
                if (t0 > curr_interval.min) curr_interval.min = t0;
                if (t1 < curr_interval.max) curr_interval.max = t1;
            } else {
                if (t1 > curr_interval.min) curr_interval.min = t1;
                if (t0 < curr_interval.max) curr_interval.max = t0;
            }

            if (curr_interval.max <= curr_interval.min) return false;
        }

        return true;
    }
};
