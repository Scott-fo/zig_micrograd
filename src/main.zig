const std = @import("std");
const value = @import("value.zig");
const ops = @import("ops.zig");
const Value = value.Value;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var x1 = try Value(f64).new(allocator, 2, "x1");
    defer x1.deinit();

    var x2 = try Value(f64).new(allocator, 0, "x2");
    defer x2.deinit();

    var w1 = try Value(f64).new(allocator, -3, "w1");
    defer w1.deinit();

    var w2 = try Value(f64).new(allocator, 1, "w2");
    defer w2.deinit();

    var b = try Value(f64).new(allocator, 6.8813735870195432, "b");
    defer b.deinit();

    var x1w1 = try ops.mul(f64, &x1, &w1, allocator);
    defer x1w1.deinit();
    x1w1.label = "x1*w1";

    var x2w2 = try ops.mul(f64, &x2, &w2, allocator);
    defer x2w2.deinit();
    x2w2.label = "x2*w2";

    var x1w1x2w2 = try ops.add(f64, &x1w1, &x2w2, allocator);
    defer x1w1x2w2.deinit();
    x1w1x2w2.label = "x1w1 + x2w2";

    var n = try ops.add(f64, &x1w1x2w2, &b, allocator);
    defer n.deinit();
    n.label = "n";

    var o = try ops.tanh(f64, &n, allocator);
    defer o.deinit();
    o.label = "o";

    try o.backward();

    const asci = try o.toAscii();
    defer allocator.free(asci);
    std.debug.print("{s}\n", .{asci});
}
