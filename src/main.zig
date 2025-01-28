const std = @import("std");
const ops = @import("ops.zig");
const Value = @import("value.zig").Value;
const Neuron = @import("Neuron.zig");
const Layer = @import("Layer.zig");
const MLP = @import("MLP.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    // try grad_example(allocator);
    // try neuron_example(allocator);
    // try layer_example(allocator);
    // try mlp_example(allocator);
    try training_example(allocator);
}

fn training_example(allocator: std.mem.Allocator) !void {
    const nouts = [3]usize{ 4, 4, 1 };

    const xs = [4][3]f64{ .{ 2, 3, -1 }, .{ 3, -1, 0.5 }, .{ 0.5, 1, 1 }, .{ 1, 1, -1 } };
    const ys = [4]f64{ 1, -1, -1, 1 };

    var mlp = try MLP.init(allocator, 3, &nouts);
    defer mlp.deinit();

    var epoch: usize = 0;
    while (epoch < 20) : (epoch += 1) {
        var loss = try Value(f64).new(allocator, 0, "loss");
        defer loss.release();

        // Zero gradients
        const params = try mlp.parameters();
        defer {
            for (params.items) |param| {
                param.release();
            }
            params.deinit();
        }

        for (params.items) |param| {
            param.grad = 0;
        }

        for (xs, ys) |x, y| {
            // Forward pass
            var pred = try mlp.call(&x);
            defer pred.deinit();

            var target = try Value(f64).new(allocator, y, null);
            defer target.release();

            switch (pred) {
                .single => |value| {
                    const diff = try ops.sub(f64, value, target, allocator);
                    defer diff.release();

                    const two = try Value(f64).new(allocator, 2, "2");
                    defer two.release();

                    const squared_error = try ops.pow(f64, diff, two, allocator);
                    defer squared_error.release();

                    const new_loss = try ops.add(f64, loss, squared_error, allocator);

                    loss.release();
                    loss = new_loss;
                },
                .multiple => unreachable,
            }
        }

        const n = try Value(f64).new(allocator, @as(f64, @floatFromInt(xs.len)), "n");
        defer n.release();

        const mean_loss = try ops.div(f64, loss, n, allocator);
        defer mean_loss.release();

        try mean_loss.backward();

        for (params.items) |param| {
            param.data -= 0.05 * param.grad;
        }

        std.debug.print("Epoch {}: Loss = {d:.4}\n", .{ epoch, mean_loss.data });
    }
}

fn mlp_example(allocator: std.mem.Allocator) !void {
    const nouts = [3]usize{ 4, 4, 1 };
    const x = [3]f64{ 2, 3, -1 };

    var mlp = try MLP.init(allocator, x.len, &nouts);
    defer mlp.deinit();

    var out = try mlp.call(&x);
    defer out.deinit();

    try out.print(allocator);

    if (out.values.items.len == 1) {
        var o = out.values.items[0];
        try o.backward();

        const asci = try o.toAscii();
        defer allocator.free(asci);

        std.debug.print("{s}\n", .{asci});
    }
}

fn layer_example(allocator: std.mem.Allocator) !void {
    var x1 = try Value(f64).new(allocator, 2, "x1");
    defer x1.release();

    var x2 = try Value(f64).new(allocator, 3, "x2");
    defer x2.release();

    var l = try Layer.init(allocator, 2, 3);
    defer l.deinit();

    var x = [2]*Value(f64){ x1, x2 };

    var res = try l.call(&x);
    defer res.deinit();

    try res.print(allocator);
}

fn neuron_example(allocator: std.mem.Allocator) !void {
    var x1 = try Value(f64).new(allocator, 2, "x1");
    defer x1.release();

    var x2 = try Value(f64).new(allocator, 3, "x2");
    defer x2.release();

    var n = try Neuron.init(allocator, 2);
    defer n.deinit();

    var x = [2]*Value(f64){ x1, x2 };

    const res = try n.call(&x);
    defer res.release();
    try res.print();
}

fn grad_example(allocator: std.mem.Allocator) !void {
    var x1 = try Value(f64).new(allocator, 2, "x1");
    defer x1.release();

    var x2 = try Value(f64).new(allocator, 0, "x2");
    defer x2.release();

    var w1 = try Value(f64).new(allocator, -3, "w1");
    defer w1.release();

    var w2 = try Value(f64).new(allocator, 1, "w2");
    defer w2.release();

    var b = try Value(f64).new(allocator, 6.8813735870195432, "b");
    defer b.release();

    var x1w1 = try ops.mul(f64, x1, w1, allocator);
    defer x1w1.release();
    x1w1.label = "x1*w1";

    var x2w2 = try ops.mul(f64, x2, w2, allocator);
    defer x2w2.release();
    x2w2.label = "x2*w2";

    var x1w1x2w2 = try ops.add(f64, x1w1, x2w2, allocator);
    defer x1w1x2w2.release();
    x1w1x2w2.label = "x1w1 + x2w2";

    var n = try ops.add(f64, x1w1x2w2, b, allocator);
    defer n.release();
    n.label = "n";

    var o = try ops.roundabout_tanh(f64, n, allocator);
    defer o.release();
    o.label = "o";

    try o.backward();

    const asci = try o.toAscii();
    defer allocator.free(asci);

    std.debug.print("{s}\n", .{asci});
}
