const std = @import("std");
const value = @import("Value.zig");
const Value = value.Value;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const a = Value(i64).init(2);
    const b = Value(i64).init(-3);

    const a_output = try a.display(allocator);
    defer allocator.free(a_output);
    std.debug.print("{s}\n", .{a_output});

    const b_output = try b.display(allocator);
    defer allocator.free(b_output);
    std.debug.print("{s}\n", .{b_output});

    const res = a.add(b);
    const res2 = a.mul(b);

    const out = try res.display(allocator);
    defer allocator.free(out);

    const out2 = try res2.display(allocator);
    defer allocator.free(out2);

    std.debug.print("{s}\n", .{out});
    std.debug.print("{s}\n", .{out2});
}
