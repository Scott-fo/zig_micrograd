const std = @import("std");

pub fn Value(comptime T: type) type {
    return struct {
        const Self = @This();

        data: T,

        pub fn init(data: T) Self {
            return .{ .data = data };
        }

        pub fn display(self: Self, gpa: std.mem.Allocator) ![]u8 {
            return std.fmt.allocPrint(gpa, "Value(data={})", .{self.data});
        }

        pub fn add(self: Self, other: Self) Self {
            return init(self.data + other.data);
        }

        pub fn mul(self: Self, other: Self) Self {
            return init(self.data * other.data);
        }
    };
}
