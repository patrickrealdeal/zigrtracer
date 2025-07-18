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
    //_ = ensureVector(v);
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

pub inline fn fill(n: anytype) Vec3 {
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
            return p / fill(@sqrt(lensq));
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

inline fn ensureVector(comptime T: type) type {
    if (@typeInfo(T) != .vector) {
        std.debug.print("T type: {?}\n", .{@TypeOf(T)});
        @compileError("ensureTypeIsVector: type is not a vector");
    }
    return T;
}

const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;

test "vector len" {
    const v1 = @Vector(1, f32){5};
    try expectEqual(@as(vtype(@TypeOf(v1)), std.math.sqrt(5 * 5)), len(v1));

    const v2 = @Vector(2, f32){ 2, 2 };
    try expectEqual(std.math.sqrt(@as(vtype(@TypeOf(v2)), (2 * 2 + 2 * 2))), len(v2));
}

test "vector unit" {
    const v1 = @Vector(1, f64){3};
    const answer = @Vector(1, f64){1};
    try expectEqual(answer, unit(v1));

    const v2 = @Vector(3, f64){ 1, 2, 3 };
    const l = std.math.sqrt(@as(f64, 1 * 1 + 2 * 2 + 3 * 3));
    const answer2 = @Vector(3, f64){
        1 / l,
        2 / l,
        3 / l,
    };
    try expectEqual(answer2, unit(v2));
}
