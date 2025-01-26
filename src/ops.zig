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

    return Value(T).init(
        allocator,
        l.data + r.data,
        &[2]*Value(T){ l, r },
        "+",
        null,
    );
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

    return Value(T).init(
        allocator,
        lhs.data * rhs.data,
        &[2]*Value(T){ l, r },
        "*",
        null,
    );
}
