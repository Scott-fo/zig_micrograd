const std = @import("std");
const value = @import("value.zig");
const Value = value.Value;

pub fn add(
    comptime T: type,
    lhs: *Value(T),
    rhs: *Value(T),
    allocator: std.mem.Allocator,
) !*Value(T) {
    var out = try Value(T).init(
        allocator,
        lhs.data + rhs.data,
        @constCast(&[_]*Value(T){ lhs, rhs }),
        "+",
        null,
    );

    out.setBackwardFn(struct {
        fn backward(self: *Value(T)) void {
            self.prev.items[0].grad += 1.0 * self.grad;
            self.prev.items[1].grad += 1.0 * self.grad;
        }
    }.backward);

    return out;
}

pub fn neg(
    comptime T: type,
    val: *Value(T),
    allocator: std.mem.Allocator,
) !*Value(T) {
    return Value(T).new(allocator, -val.data, val.label);
}

pub fn sub(
    comptime T: type,
    lhs: *Value(T),
    rhs: *Value(T),
    allocator: std.mem.Allocator,
) !*Value(T) {
    const negative = try neg(T, rhs, allocator);
    defer negative.release();

    return add(T, lhs, negative, allocator);
}

pub fn mul(
    comptime T: type,
    lhs: *Value(T),
    rhs: *Value(T),
    allocator: std.mem.Allocator,
) !*Value(T) {
    var out = try Value(T).init(
        allocator,
        lhs.data * rhs.data,
        @constCast(&[_]*Value(T){ lhs, rhs }),
        "*",
        null,
    );

    out.setBackwardFn(struct {
        fn backward(self: *Value(T)) void {
            self.prev.items[0].grad += toF64(T, self.prev.items[1].data) * self.grad;
            self.prev.items[1].grad += toF64(T, self.prev.items[0].data) * self.grad;
        }
    }.backward);

    return out;
}

pub fn div(
    comptime T: type,
    lhs: *Value(T),
    rhs: *Value(T),
    allocator: std.mem.Allocator,
) !*Value(T) {
    var neg_one = try Value(T).new(allocator, -1, "neg_one");
    defer neg_one.release();

    const exponent = try pow(T, rhs, neg_one, allocator);
    defer exponent.release();

    return mul(T, lhs, exponent, allocator);
}

pub fn pow(
    comptime T: type,
    base: *Value(T),
    power: *Value(T),
    allocator: std.mem.Allocator,
) !*Value(T) {
    var out = try Value(T).init(
        allocator,
        std.math.pow(T, base.data, power.data),
        @constCast(&[_]*Value(T){ base, power }),
        "**",
        null,
    );

    out.setBackwardFn(struct {
        fn backward(self: *Value(T)) void {
            self.prev.items[0].grad +=
                toF64(T, self.prev.items[1].data) *
                std.math.pow(T, self.prev.items[0].data, self.prev.items[1].data - 1) *
                self.grad;

            self.prev.items[1].grad +=
                std.math.pow(T, self.prev.items[0].data, self.prev.items[1].data) *
                @log(toF64(T, self.prev.items[0].data)) *
                self.grad;
        }
    }.backward);

    return out;
}

pub fn exp(
    comptime T: type,
    val: *Value(T),
    allocator: std.mem.Allocator,
) !*Value(T) {
    var e = try Value(T).new(allocator, std.math.e, "e");
    defer e.release();

    return pow(T, e, val, allocator);
}

pub fn tanh(
    comptime T: type,
    val: *Value(T),
    allocator: std.mem.Allocator,
) !*Value(T) {
    const res = (@exp(2 * val.data) - 1) / (@exp(2 * val.data) + 1);

    var out = try Value(T).init(
        allocator,
        res,
        @constCast(&[_]*Value(T){val}),
        "tanh",
        null,
    );

    out.setBackwardFn(struct {
        fn backward(self: *Value(T)) void {
            self.prev.items[0].grad += (1 - toF64(T, (self.data * self.data))) * self.grad;
        }
    }.backward);

    return out;
}

fn toF64(comptime T: type, val: T) f64 {
    return switch (@typeInfo(T)) {
        .int => @as(f64, @floatFromInt(val)),
        .float => val,
        else => @compileError("Unsupported type"),
    };
}

pub fn roundabout_tanh(
    comptime T: type,
    n: *Value(T),
    allocator: std.mem.Allocator,
) !*Value(T) {
    const two = try Value(T).new(allocator, 2, "2");
    defer two.release();
    const two_n = try mul(T, two, n, allocator);
    defer two_n.release();

    const e_2n = try exp(T, two_n, allocator);
    defer e_2n.release();

    const one = try Value(T).new(allocator, 1, "1");
    defer one.release();

    const num = try sub(T, e_2n, one, allocator);
    defer num.release();

    const denom = try add(T, e_2n, one, allocator);
    defer denom.release();

    return div(T, num, denom, allocator);
}
