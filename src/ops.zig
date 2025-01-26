const std = @import("std");
const value = @import("value.zig");
const Value = value.Value;

pub fn add(
    comptime T: type,
    lhs: Value(T),
    rhs: Value(T),
    allocator: std.mem.Allocator,
) !Value(T) {
    const l = try allocator.create(Value(T));
    l.* = lhs;

    const r = try allocator.create(Value(T));
    r.* = rhs;

    var out = try Value(T).init(
        allocator,
        l.data + r.data,
        &[2]*Value(T){ l, r },
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

pub fn mul(
    comptime T: type,
    lhs: Value(T),
    rhs: Value(T),
    allocator: std.mem.Allocator,
) !Value(T) {
    const l = try allocator.create(Value(T));
    l.* = lhs;

    const r = try allocator.create(Value(T));
    r.* = rhs;

    var out = try Value(T).init(
        allocator,
        lhs.data * rhs.data,
        &[2]*Value(T){ l, r },
        "*",
        null,
    );

    out.setBackwardFn(struct {
        fn backward(self: *Value(T)) void {
            self.prev.items[0].grad += self.prev.items[1].data * self.grad;
            self.prev.items[1].grad += self.prev.items[0].data * self.grad;
        }
    }.backward);

    return out;
}

pub fn tanh(
    comptime T: type,
    val: Value(T),
    allocator: std.mem.Allocator,
) !Value(T) {
    const s = try allocator.create(Value(T));
    s.* = val;

    const res = (@exp(2 * val.data) - 1) / (@exp(2 * val.data) + 1);

    var out = try Value(T).init(
        allocator,
        res,
        &[1]*Value(T){s},
        "tanh",
        null,
    );

    out.setBackwardFn(struct {
        fn backward(self: *Value(T)) void {
            self.prev.items[0].grad += (1 - (self.data * self.data)) * self.grad;
        }
    }.backward);

    return out;
}
