const std = @import("std");

pub fn Value(comptime T: type) type {
    return struct {
        const Self = @This();

        data: T,
        gpa: std.mem.Allocator,
        prev: std.ArrayList(*Self),
        op: ?[]const u8,
        label: ?[]const u8,

        pub fn init(gpa: std.mem.Allocator, data: T, prev: ?[]const *Self, op: ?[]const u8, label: ?[]const u8) !Self {
            var list = std.ArrayList(*Self).init(gpa);
            if (prev) |p| {
                try list.appendSlice(p);
            }

            return .{
                .data = data,
                .gpa = gpa,
                .prev = list,
                .op = op,
                .label = label,
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

        pub fn toAscii(self: Self) ![]u8 {
            var list = std.ArrayList(u8).init(self.gpa);
            errdefer list.deinit();

            try self.buildAscii(&list, "", true);
            return list.toOwnedSlice();
        }

        fn buildAscii(self: Self, list: *std.ArrayList(u8), prefix: []const u8, is_last: bool) !void {
            try std.fmt.format(list.writer(), "{s}({s}) {} {s}\n", .{
                prefix,
                self.label orelse "",
                self.data,
                self.op orelse "",
            });

            for (self.prev.items, 0..) |p, i| {
                const is_last_child = i == self.prev.items.len - 1;
                const new_prefix = try std.fmt.allocPrint(self.gpa, "{s}{s}", .{
                    prefix,
                    if (is_last) "       " else "│      ",
                });
                defer self.gpa.free(new_prefix);
                try p.buildAscii(list, new_prefix, is_last_child);
            }
        }
    };
}
