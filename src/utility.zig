const std = @import("std");

pub const Random = std.Random;

pub fn degrees_to_radians(d: f64) f64 {
    return d * std.math.pi / 180.0;
}

pub fn genRand(random: Random, comptime T: type) T {
    return switch (@typeInfo(T)) {
        .comptime_float, .float => random.float(T),
        .comptime_int, .int => random.int(T),
        else => @compileError("Rand not implemented fot type " ++ @typeName(T)),
    };
}

pub fn genRandRange(random: Random, comptime T: type, min: T, max: T) T {
    return min + (max - min) * genRand(random, T);
}

test "d_to_r" {
    const d = 60.0;
    const result = degrees_to_radians(d);
    std.debug.print("{d}\n", .{result});
}

test "rand generator" {
    const seed = std.time.milliTimestamp();

    var prng = Random.DefaultPrng.init(@intCast(seed));
    const random = prng.random();
    const r1 = genRand(random, f64);
    const r2 = genRand(random, i32);
    std.debug.print("{d} {d}\n", .{ r1, r2 });
}

test "rand range" {
    const seed = std.time.milliTimestamp();

    var prng = Random.DefaultPrng.init(@intCast(seed));
    const random = prng.random();
    const r1 = genRandRange(random, f64, 0, 1);
    std.debug.print("range: {d:.2}\n", .{r1});
}
