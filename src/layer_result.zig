const std = @import("std");
const Value = @import("value.zig").Value;

pub const LayerResult = union(enum) {
    const Self = @This();
    single: *Value(f64),
    multiple: std.ArrayList(*Value(f64)),

    pub fn deinit(self: *Self) void {
        switch (self.*) {
            .single => |value| {
                value.release();
            },
            .multiple => |values| {
                for (values.items) |value| {
                    value.release();
                }

                values.deinit();
            },
        }
    }

    pub fn print(self: *Self, allocator: std.mem.Allocator) !void {
        switch (self.*) {
            .single => |value| {
                const res_string = try value.string();
                defer allocator.free(res_string);

                std.debug.print("  {s},\n", .{res_string});
            },
            .multiple => |values| {
                std.debug.print("\nLayer=[\n", .{});
                for (values.items) |out| {
                    const res_string = try out.string();
                    defer allocator.free(res_string);

                    std.debug.print("  {s},\n", .{res_string});
                }
                std.debug.print("]\n", .{});
            },
        }
    }
};
