const std = @import("std");
const Neuron = @import("Neuron.zig");
const Value = @import("value.zig").Value;
const LayerOutput = @import("LayerOutput.zig");

const Self = @This();

allocator: std.mem.Allocator,
neurons: std.ArrayList(*Neuron),

pub fn init(
    allocator: std.mem.Allocator,
    nin: usize,
    nout: usize,
) !Self {
    var list = std.ArrayList(*Neuron).init(allocator);
    try list.ensureTotalCapacity(nout);

    var prng = std.Random.DefaultPrng.init(@intCast(
        std.time.milliTimestamp(),
    ));

    const random = prng.random();

    var i = nout;
    while (i > 0) : (i -= 1) {
        const n = try allocator.create(Neuron);
        n.* = try Neuron.init_with_rand(allocator, nin, random);
        try list.append(n);
    }

    return .{
        .allocator = allocator,
        .neurons = list,
    };
}

pub fn deinit(self: *Self) void {
    for (self.neurons.items) |neuron| {
        neuron.deinit();
        self.allocator.destroy(neuron);
    }

    self.neurons.deinit();
}

pub fn call(self: *Self, x: []*Value(f64)) !LayerOutput {
    var values = std.ArrayList(*Value(f64)).init(self.allocator);
    errdefer values.deinit();

    for (self.neurons.items) |neuron| {
        const out = try neuron.call(x);
        errdefer out.release();

        try values.append(out);
    }

    return .{ .values = values };
}
