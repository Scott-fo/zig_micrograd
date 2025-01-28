const std = @import("std");
const Layer = @import("Layer.zig");
const Value = @import("value.zig").Value;
const LayerResult = @import("layer_result.zig").LayerResult;

const Self = @This();

const MLPError = error{
    InvalidInputSize,
};

allocator: std.mem.Allocator,
layers: std.ArrayList(*Layer),
nin: usize,

pub fn init(allocator: std.mem.Allocator, nin: usize, comptime nouts: []const usize) !Self {
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

pub fn call(self: *Self, x: []const f64) !LayerResult {
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
        errdefer val.release();

        try current.append(val);
    }

    for (self.layers.items, 0..) |layer, i| {
        var layer_output = try layer.call(current.items);
        defer {
            if (i < self.layers.items.len - 1) {
                layer_output.deinit();
            }
        }

        if (i < self.layers.items.len - 1) {
            switch (layer_output) {
                .single => |value| {
                    value.retain();
                    try next.append(value);
                },
                .multiple => |values| {
                    for (values.items) |value| {
                        value.retain();
                    }

                    try next.appendSlice(values.items);
                },
            }

            for (current.items) |value| value.release();
            current.clearRetainingCapacity();

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

pub fn parameters(self: *Self) !std.ArrayList(*Value(f64)) {
    var params = std.ArrayList(*Value(f64)).init(self.allocator);
    errdefer params.deinit();

    for (self.layers.items) |layer| {
        var layer_params = try layer.parameters();
        defer layer_params.deinit();

        try params.appendSlice(layer_params.items);
    }

    return params;
}
