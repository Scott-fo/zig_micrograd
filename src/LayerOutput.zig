const std = @import("std");
const Value = @import("value.zig").Value;

const Self = @This();

values: std.ArrayList(*Value(f64)),

pub fn deinit(self: *Self) void {
    for (self.values.items) |value| {
        value.release();
    }

    self.values.deinit();
}

pub fn print(self: *Self, allocator: std.mem.Allocator) !void {
    std.debug.print("\nLayer=[\n", .{});
    for (self.values.items) |out| {
        const res_string = try out.string();
        defer allocator.free(res_string);

        std.debug.print("  {s},\n", .{res_string});
    }
    std.debug.print("]\n", .{});
}
