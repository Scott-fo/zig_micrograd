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
                p.deinit();
                self.gpa.destroy(p);
            }
            self.prev.deinit();
        }

        pub fn display(self: Self) ![]u8 {
            return std.fmt.allocPrint(self.gpa, "Value(data={})", .{self.data});
        }
    };
}
