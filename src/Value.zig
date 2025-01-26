const std = @import("std");

pub fn Value(comptime T: type) type {
    return struct {
        const Self = @This();

        data: T,
        children: std.ArrayList(*Self),

        pub fn init(gpa: std.mem.Allocator, data: T, children: ?[]const *Self) !Self {
            var list = std.ArrayList(*Self).init(gpa);
            if (children) |c| {
                try list.appendSlice(c);
            }

            return .{
                .data = data,
                .children = list,
            };
        }

        pub fn deinit(self: *Self) void {
            self.children.deinit();
        }

        pub fn display(self: Self, gpa: std.mem.Allocator) ![]u8 {
            return std.fmt.allocPrint(gpa, "Value(data={})", .{self.data});
        }

        pub fn add(self: Self, other: Self, gpa: std.mem.Allocator) !Self {
            return init(gpa, self.data + other.data, null);
        }

        pub fn mul(self: Self, other: Self, gpa: std.mem.Allocator) !Self {
            return init(gpa, self.data * other.data, null);
        }
    };
}
