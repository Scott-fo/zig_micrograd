const std = @import("std");
const Layer = @import("Layer.zig");
const Value = @import("value.zig").Value;
const LayerOutput = @import("LayerOutput.zig");

const Self = @This();

allocator: std.mem.Allocator,
layers: std.ArrayList(*Layer),

pub fn init(allocator: std.mem.Allocator, nin: usize, nouts: []const usize) !Self {
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
    };
}

pub fn deinit(self: *Self) void {
    for (self.layers.items) |layer| {
        layer.deinit();
        self.allocator.destroy(layer);
    }

    self.layers.deinit();
}

pub fn call(self: *Self, x: []f64) !LayerOutput {
    var current = std.ArrayList(*Value(f64)).init(self.allocator);
    defer current.deinit();

    var next = std.ArrayList(*Value(f64)).init(self.allocator);
    defer next.deinit();

    try current.ensureTotalCapacity(x.len);
    for (x) |value| {
        var val = try Value(f64).new(self.allocator, value, null);
        defer val.release();

        val.reference();
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
