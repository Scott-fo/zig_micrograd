const std = @import("std");

pub fn Value(comptime T: type) type {
    return struct {
        const Self = @This();

        data: T,
        gpa: std.mem.Allocator,
        prev: std.ArrayList(*Self),

        pub fn init(gpa: std.mem.Allocator, data: T, prev: ?[]const *Self) !Self {
            var list = std.ArrayList(*Self).init(gpa);
            if (prev) |p| {
                try list.appendSlice(p);
            }

            return .{
                .data = data,
                .gpa = gpa,
                .prev = list,
            };
        }

        pub fn deinit(self: *Self) void {
            for (self.prev.items) |p| {
                self.gpa.destroy(p);
            }
            self.prev.deinit();
        }

        pub fn string(self: Self) ![]u8 {
            return std.fmt.allocPrint(self.gpa, "Value(data={})", .{self.data});
        }

        pub fn prevString(self: Self) ![]u8 {
            if (self.prev.items.len == 0) {
                return &.{};
            }

            var list = std.ArrayList(u8).init(self.gpa);
            errdefer list.deinit();

            try list.appendSlice("Prev: [");
            for (self.prev.items, 0..) |p, i| {
                const p_str = try p.string();
                defer self.gpa.free(p_str);
                try list.appendSlice(p_str);
                if (i < self.prev.items.len - 1) try list.appendSlice(", ");
            }
            try list.appendSlice("]");

            return list.toOwnedSlice();
        }
    };
}
