const std = @import("std");
const value = @import("value.zig");
const ops = @import("ops.zig");
const Value = value.Value;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var x1 = try Value(f64).init(allocator, 2, null, null, "x1");
    defer x1.deinit();

    var x2 = try Value(f64).init(allocator, 0, null, null, "x2");
    defer x2.deinit();

    var w1 = try Value(f64).init(allocator, -3, null, null, "w1");
    defer w1.deinit();

    var w2 = try Value(f64).init(allocator, 1, null, null, "w2");
    defer w2.deinit();

    var b = try Value(f64).init(allocator, 6.8813735870195432, null, null, "b");
    defer b.deinit();

    var x1w1 = try ops.mul(f64, x1, w1, allocator);
    x1w1.label = "x1*w1";
    defer x1w1.deinit();

    var x2w2 = try ops.mul(f64, x2, w2, allocator);
    x2w2.label = "x2*w2";
    defer x2w2.deinit();

    var x1w1x2w2 = try ops.add(f64, x1w1, x2w2, allocator);
    x1w1x2w2.label = "x1w1 + x2w2";
    defer x1w1x2w2.deinit();

    var n = try ops.add(f64, x1w1x2w2, b, allocator);
    n.label = "n";
    defer n.deinit();

    var o = try ops.tanh(f64, n, allocator);
    o.label = "o";
    defer o.deinit();

    o.grad = 1.0;
    o.backward();

    const asci = try o.toAscii();
    defer allocator.free(asci);

    std.debug.print("{s}\n", .{asci});
}
