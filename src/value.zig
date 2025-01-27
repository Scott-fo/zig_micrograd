const std = @import("std");

pub fn Value(comptime T: type) type {
    switch (@typeInfo(T)) {
        .int, .float => {},
        else => @compileError("Value type must be numeric"),
    }

    return struct {
        const Self = @This();

        gpa: std.mem.Allocator,

        data: T,

        grad: f64,
        backward_fn: ?*const fn (*Self) void = null,

        prev: std.ArrayList(*const Self),
        op: ?[]const u8,
        label: ?[]const u8,

        pub fn new(gpa: std.mem.Allocator, data: T, label: ?[]const u8) !Self {
            const list = std.ArrayList(*const Self).init(gpa);

            return .{
                .data = data,
                .grad = 0,
                .gpa = gpa,
                .prev = list,
                .op = null,
                .label = label,
            };
        }

        pub fn init(
            gpa: std.mem.Allocator,
            data: T,
            prev: ?[]const *const Self,
            op: ?[]const u8,
            label: ?[]const u8,
        ) !Self {
            var list = std.ArrayList(*const Self).init(gpa);
            if (prev) |p| {
                try list.appendSlice(p);
            }

            return .{
                .data = data,
                .grad = 0,
                .gpa = gpa,
                .prev = list,
                .op = op,
                .label = label,
            };
        }

        pub fn deinit(self: *Self) void {
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
            try std.fmt.format(list.writer(), "{s}({s}) {} {s} grad={}\n", .{
                prefix,
                self.label orelse "",
                self.data,
                self.op orelse "",
                self.grad,
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

        pub fn setBackwardFn(self: *Self, func: *const fn (*Self) void) void {
            self.backward_fn = func;
        }

        pub fn backward(self: *Self) !void {
            self.grad = 1.0;

            var topo = std.ArrayList(*const Self).init(self.gpa);
            defer topo.deinit();

            try self.build_topo(&topo);

            var i = topo.items.len;
            while (i > 0) : (i -= 1) {
                if (topo.items[i - 1].backward_fn) |f| {
                    f(@constCast(topo.items[i - 1]));
                }
            }
        }

        pub fn build_topo(
            self: *const Self,
            topo: *std.ArrayList(*const Self),
        ) !void {
            var visited = std.AutoHashMap(*const Self, void).init(self.gpa);
            defer visited.deinit();

            try build_topo_inner(self, topo, &visited);
        }

        fn build_topo_inner(
            self: *const Self,
            topo: *std.ArrayList(*const Self),
            visited: *std.AutoHashMap(*const Self, void),
        ) !void {
            if (visited.contains(self)) return;
            try visited.put(self, {});

            for (self.prev.items) |child| {
                try build_topo_inner(child, topo, visited);
            }

            try topo.append(self);
        }
    };
}
