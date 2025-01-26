const std = @import("std");
const value = @import("value.zig");
const ops = @import("ops.zig");
const Value = value.Value;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var a = try Value(i64).init(allocator, 2, null, null, "a");
    defer a.deinit();

    var b = try Value(i64).init(allocator, -3, null, null, "b");
    defer b.deinit();

    var c = try Value(i64).init(allocator, 10, null, null, "c");
    defer c.deinit();

    var e = try ops.mul(i64, a, b, allocator);
    e.label = "e";
    defer e.deinit();

    var d = try ops.add(i64, e, c, allocator);
    d.label = "d";
    defer d.deinit();

    var f = try Value(i64).init(allocator, -2, null, null, "f");
    defer f.deinit();

    var L = try ops.mul(i64, d, f, allocator);
    L.label = "L";
    defer L.deinit();

    const asci = try L.toAscii();
    defer allocator.free(asci);

    std.debug.print("{s}\n", .{asci});
}
