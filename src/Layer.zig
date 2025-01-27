const std = @import("std");
const Neuron = @import("Neuron.zig");
const Value = @import("value.zig").Value;

const Self = @This();

allocator: std.mem.Allocator,
neurons: std.ArrayList(*Neuron),

pub fn init(
    allocator: std.mem.Allocator,
    nin: usize,
    nout: usize,
    rand: std.Random,
) !Self {
    var list = std.ArrayList(*Neuron).init(allocator);
    try list.ensureTotalCapacity(nout);

    var i = nout;
    while (i > 0) : (i -= 1) {
        const n = try allocator.create(Neuron);
        n.* = try Neuron.init(allocator, nin, rand);
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

pub fn call(self: *Self, x: []*Value(f64)) !std.ArrayList(*Value(f64)) {
    var res = std.ArrayList(*Value(f64)).init(self.allocator);

    for (self.neurons.items) |neuron| {
        const out = try neuron.call(x);
        try res.append(out);
    }

    return res;
}
