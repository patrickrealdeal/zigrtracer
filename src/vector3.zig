const std = @import("std");
const Random = std.Random;
const Writer = std.io.Writer;

pub const Vec3 = @Vector(3, f64);
pub const Point = Vec3;

pub const zero: Vec3 = .{ 0, 0, 0 };

pub fn vtype(comptime T: type) type {
    _ = ensureVector(T);
    return @typeInfo(T).vector.child;
}

inline fn vsize(comptime T: type) comptime_int {
    _ = ensureVector(T);
    return @typeInfo(T).vector.len;
}

pub fn magnitude(v: Vec3) f64 {
    // const sqsum: f64 = v[0]*v[0] + v[1]*v[1] + v[2]*v[2];
    // return std.math.sqrt(sqsum);
    return @sqrt(magnitude2(v));
}
pub fn magnitude2(v: Vec3) f64 {
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
    const len_vec = magnitude(v);
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

pub fn toGamma(color: f64) f64 {
    return if (color > 0) @sqrt(color) else 0;
}

pub fn random(r: std.Random) Vec3 {
    return .{ r.float(f64), r.float(f64), r.float(f64) };
}

pub fn randomRange(r: std.Random, min: f64, max: f64) Vec3 {
    std.debug.assert(max >= min);
    return .{
        r.float(f64) * (max - min) + min,
        r.float(f64) * (max - min) + min,
        r.float(f64) * (max - min) + min,
    };
}

pub fn randomUnit(r: Random) Vec3 {
    while (true) {
        const v = randomRange(r, -1, 1);
        const m2 = magnitude2(v);
        if (std.math.floatEpsAt(f64, 0) < m2 and m2 <= 1) {
            // if (1e-160 < m2 and m2 <= 1) {
            return v / @sqrt(splat(m2));
        }
    }
}

pub fn randomInUnitDisk(r: std.Random) Vec3 {
    while (true) {
        var p = randomRange(r, -1, 1);
        p[2] = 0;
        if (magnitude2(p) < 1) {
            return p;
        }
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
    const r_out_parallel = splat(-@sqrt(@abs(1.0 - magnitude2(r_out_perp)))) * v2;
    return r_out_perp + r_out_parallel;
}

pub const Color = std.fmt.Alt(Vec3, colorFormat);
fn colorFormat(v: Vec3, w: *Writer) !void {
    const _x: u8 = @intFromFloat(v[0] * 255.999);
    const _y: u8 = @intFromFloat(v[1] * 255.999);
    const _z: u8 = @intFromFloat(v[2] * 255.999);
    try w.print("{d} {d} {d}\n", .{ _x, _y, _z });
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
