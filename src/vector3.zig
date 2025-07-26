const std = @import("std");
const random = @import("utility.zig");
const Random = random.Random;

pub const Vec3 = @Vector(3, f64);
pub const Point = Vec3;

pub fn vtype(comptime T: type) type {
    _ = ensureVector(T);
    return @typeInfo(T).vector.child;
}

inline fn vsize(comptime T: type) comptime_int {
    _ = ensureVector(T);
    return @typeInfo(T).vector.len;
}

pub inline fn len(v: anytype) vtype(@TypeOf(v)) {
    return std.math.sqrt(dot(v, v));
}

pub inline fn lenSquared(v: anytype) vtype(@TypeOf(v)) {
    return @reduce(.Add, v * v);
}

pub fn dot(v1: anytype, v2: anytype) vtype(@TypeOf(v1)) {
    const vt1 = ensureVector(@TypeOf(v1));
    const vt2 = ensureVector(@TypeOf(v2));
    if (vt1 != vt2) {
        @compileError("dot: vectors must be of the same type");
    }
    return @reduce(.Add, v1 * v2);
}

pub fn cross(v1: anytype, v2: anytype) @TypeOf(v1) {
    const vt1 = ensureVector(@TypeOf(v1));
    const vt2 = ensureVector(@TypeOf(v2));
    if (vt1 != vt2) {
        @compileError("dot: vectors must be of the same type");
    }

    return vt1{
        v1[1] * v2[2] - v1[2] * v2[1],
        v1[2] * v2[0] - v1[0] * v2[2],
        v1[0] * v2[1] - v1[1] * v2[0],
    };
}

pub fn unit(v: anytype) @TypeOf(v) {
    const T = @TypeOf(v);
    const len_vec = len(v);
    return v / @as(T, @splat(len_vec));
}

pub inline fn splat(n: anytype) Vec3 {
    const type_info = @typeInfo(@TypeOf(n));
    switch (type_info) {
        .comptime_int, .int => return @splat(@floatFromInt(n)),
        else => {},
    }
    return @splat(n);
}

pub fn randomV(prng: *Random.DefaultPrng) Vec3 {
    const rng = prng.random();
    return Vec3{ random.genRand(rng, f64), random.genRand(rng, f64), random.genRand(rng, f64) };
}

pub fn randomInRange(prng: *Random.DefaultPrng, min: f64, max: f64) Vec3 {
    const rng = prng.random();
    return Vec3{ random.genRandRange(rng, f64, min, max), random.genRandRange(rng, f64, min, max), random.genRandRange(rng, f64, min, max) };
}

pub fn randomUnit(prng: *Random.DefaultPrng) Vec3 {
    while (true) {
        const p = randomInRange(prng, -1, 1);
        const lensq = lenSquared(p);
        if (1e-160 < lensq and lensq <= 1) {
            return p / splat(@sqrt(lensq));
        }
    }
}

pub fn randomOnHemisphere(prng: *Random.DefaultPrng, normal: *Vec3) Vec3 {
    const on_unit_sphere = randomUnit(prng);
    if (dot(on_unit_sphere, normal.*) > 0) { // In the same hemisphere as the normal
        return on_unit_sphere;
    } else {
        return -on_unit_sphere;
    }
}

pub fn nearZero(v: anytype) bool {
    const s = 1e-8;
    return @reduce(.And, @abs(v) < splat(s));
}

pub fn reflect(v: anytype, n: anytype) @TypeOf(v) {
    return v - splat(2 * dot(v, n)) * n;
}

pub fn refract(v1: anytype, v2: anytype, etai_over_etat: f64) @TypeOf(v1) {
    const cos_theta = @min(dot(-v1, v2), 1.0);
    const r_out_perp = splat(etai_over_etat) * (v1 + (splat(cos_theta) * v2));
    const r_out_parallel = splat(-@sqrt(@abs(1.0 - lenSquared(r_out_perp)))) * v2;
    return r_out_perp + r_out_parallel;
}

inline fn ensureVector(comptime T: type) type {
    if (@typeInfo(T) != .vector) {
        std.debug.print("T type: {?}\n", .{@TypeOf(T)});
        @compileError("ensureTypeIsVector: type is not a vector");
    }
    return T;
}

// const expectEqual = std.testing.expectEqual;
// const expect = std.testing.expect;
