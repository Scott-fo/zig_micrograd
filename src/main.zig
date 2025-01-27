const std = @import("std");
const ops = @import("ops.zig");
const Value = @import("value.zig").Value;
const Neuron = @import("neuron.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    try grad_example(allocator);
    try neuron_example(allocator);
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

    const res_string = try res.string();
    defer allocator.free(res_string);

    std.debug.print("Value(data={s})\n", .{res_string});
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
