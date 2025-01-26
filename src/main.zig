const std = @import("std");
const value = @import("value.zig");
const ops = @import("ops.zig");
const Value = value.Value;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var a = try Value(i64).init(allocator, 2, null);
    defer a.deinit();

    var b = try Value(i64).init(allocator, -3, null);
    defer b.deinit();

    var c = try Value(i64).init(allocator, 10, null);
    defer c.deinit();

    var d_temp = try ops.mul(i64, a, b, allocator);
    defer d_temp.deinit();

    var d = try ops.add(i64, d_temp, c, allocator);
    defer d.deinit();

    const d_string = try d.string();
    defer allocator.free(d_string);

    std.debug.print("{s}\n", .{d_string});

    const d_prev_string = try d.prevString();
    defer allocator.free(d_prev_string);

    std.debug.print("{s}\n", .{d_prev_string});
}
