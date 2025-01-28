const std = @import("std");
const Layer = @import("Layer.zig");
const Value = @import("value.zig").Value;
const LayerOutput = @import("LayerOutput.zig");

const Self = @This();

const MLPError = error{
    InvalidInputSize,
};

allocator: std.mem.Allocator,
layers: std.ArrayList(*Layer),
nin: usize,

pub fn init(allocator: std.mem.Allocator, comptime nin: usize, comptime nouts: []const usize) !Self {
    comptime {
        if (nouts.len == 0) @compileError("Network must have at least one layer");
    }

    var layers = std.ArrayList(*Layer).init(allocator);
    errdefer {
        for (layers.items) |layer| {
            layer.deinit();
            allocator.destroy(layer);
        }

        layers.deinit();
    }

    var prev_size = nin;

    for (nouts) |size| {
        const layer = try allocator.create(Layer);
        layer.* = try Layer.init(allocator, prev_size, size);

        try layers.append(layer);
        prev_size = size;
    }

    return .{
        .allocator = allocator,
        .layers = layers,
        .nin = nin,
    };
}

pub fn deinit(self: *Self) void {
    for (self.layers.items) |layer| {
        layer.deinit();
        self.allocator.destroy(layer);
    }

    self.layers.deinit();
}

pub fn call(self: *Self, comptime x: []const f64) !LayerOutput {
    if (x.len != self.nin) {
        std.debug.print("Input size mismatch: expected {}, got {}\n", .{ self.nin, x.len });
        return MLPError.InvalidInputSize;
    }

    var current = std.ArrayList(*Value(f64)).init(self.allocator);
    defer current.deinit();

    var next = std.ArrayList(*Value(f64)).init(self.allocator);
    defer next.deinit();

    try current.ensureTotalCapacity(x.len);
    for (x) |value| {
        const val = try Value(f64).new(self.allocator, value, null);
        try current.append(val);
    }

    for (self.layers.items, 0..) |layer, i| {
        var layer_output = try layer.call(current.items);

        if (i < self.layers.items.len - 1) {
            try next.appendSlice(layer_output.values.items);

            for (current.items) |value| value.release();
            current.clearRetainingCapacity();

            layer_output.values.clearRetainingCapacity();
            layer_output.values.deinit();

            std.mem.swap(std.ArrayList(*Value(f64)), &current, &next);
            next.clearRetainingCapacity();
        } else {
            for (current.items) |value| value.release();
            current.clearRetainingCapacity();

            return layer_output;
        }
    }

    unreachable;
}
