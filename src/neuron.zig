const std = @import("std");

const value = @import("value.zig");
const Value = value.Value;

const ops = @import("ops.zig");

const Self = @This();

allocator: std.mem.Allocator,
w: std.ArrayList(*Value(f64)),
b: *Value(f64),

pub fn init(
    allocator: std.mem.Allocator,
    nin: usize,
) !Self {
    var w = std.ArrayList(*Value(f64)).init(allocator);
    try w.ensureTotalCapacity(nin);

    var random = std.Random.DefaultPrng.init(@intCast(
        std.time.milliTimestamp(),
    ));

    var i: usize = 0;
    while (i < nin) : (i += 1) {
        const rand_val = random.random().float(f64) * 2 - 1;
        const weight = try Value(f64).new(allocator, rand_val, "w");
        try w.append(weight);
    }

    const bias_val = random.random().float(f64) * 2 - 1;
    const bias = try Value(f64).new(allocator, bias_val, "b");

    return .{
        .allocator = allocator,
        .w = w,
        .b = bias,
    };
}

pub fn deinit(self: *Self) void {
    for (self.w.items) |weight| {
        weight.release();
    }

    self.w.deinit();
    self.b.release();
}

pub fn call(self: Self, x: []*Value(f64)) !*Value(f64) {
    var sum = try ops.mul(f64, self.w.items[0], x[0], self.allocator);
    defer sum.release();

    for (self.w.items[1..], x[1..]) |wi, xi| {
        const prod = try ops.mul(f64, wi, xi, self.allocator);
        defer prod.release();

        const new_sum = try ops.add(f64, sum, prod, self.allocator);
        sum.release();

        sum = new_sum;
    }

    const with_bias = try ops.add(f64, sum, self.b, self.allocator);
    defer with_bias.release();

    return ops.tanh(f64, with_bias, self.allocator);
}
