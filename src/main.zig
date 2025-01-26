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

    const a_output = try a.display();
    defer allocator.free(a_output);
    std.debug.print("{s}\n", .{a_output});

    const b_output = try b.display();
    defer allocator.free(b_output);
    std.debug.print("{s}\n", .{b_output});

    var res = try ops.add(i64, a, b, allocator);
    defer res.deinit();

    var res2 = try ops.mul(i64, a, b, allocator);
    defer res2.deinit();

    const out = try res.display();
    defer allocator.free(out);

    const out2 = try res2.display();
    defer allocator.free(out2);

    std.debug.print("{s}\n", .{out});
    std.debug.print("{s}\n", .{out2});
}
