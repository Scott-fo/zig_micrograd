const std = @import("std");
const value = @import("value.zig");
const Value = value.Value;

pub fn add(
    comptime T: type,
    lhs: *const Value(T),
    rhs: *const Value(T),
    allocator: std.mem.Allocator,
) !Value(T) {
    var out = try Value(T).init(
        allocator,
        lhs.data + rhs.data,
        &[2]*const Value(T){ lhs, rhs },
        "+",
        null,
    );

    out.setBackwardFn(struct {
        fn backward(self: *Value(T)) void {
            @constCast(self.prev.items[0]).grad += 1.0 * self.grad;
            @constCast(self.prev.items[1]).grad += 1.0 * self.grad;
        }
    }.backward);

    return out;
}

pub fn mul(
    comptime T: type,
    lhs: *const Value(T),
    rhs: *const Value(T),
    allocator: std.mem.Allocator,
) !Value(T) {
    var out = try Value(T).init(
        allocator,
        lhs.data * rhs.data,
        &[2]*const Value(T){ lhs, rhs },
        "*",
        null,
    );

    out.setBackwardFn(struct {
        fn backward(self: *Value(T)) void {
            @constCast(self.prev.items[0]).grad += @constCast(self.prev.items[1]).data * self.grad;
            @constCast(self.prev.items[1]).grad += @constCast(self.prev.items[0]).data * self.grad;
        }
    }.backward);

    return out;
}

pub fn tanh(
    comptime T: type,
    val: *const Value(T),
    allocator: std.mem.Allocator,
) !Value(T) {
    const res = (@exp(2 * val.data) - 1) / (@exp(2 * val.data) + 1);

    var out = try Value(T).init(
        allocator,
        res,
        &[1]*const Value(T){val},
        "tanh",
        null,
    );

    out.setBackwardFn(struct {
        fn backward(self: *Value(T)) void {
            @constCast(self.prev.items[0]).grad += (1 - (self.data * self.data)) * self.grad;
        }
    }.backward);

    return out;
}
