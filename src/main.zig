const std = @import("std");
const fs = @import("./component/fs.zig");
const cfg = @import("./component/config.zig");

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const fileSystem = try fs.FileSystem.init(allocator);
    defer fileSystem.deinit();

    var listOfConfigs: [1][]const u8 = undefined;
    listOfConfigs[0] = ".task.toml";
    const tryFile = try fileSystem.findConfig(".", &listOfConfigs);
    if (tryFile) |file| {
        const config = try cfg.Config.init(file, allocator);
        defer config.deinit();
        _ = try config.getTask("qwe");
    } else {
        try stdout.print("failed to get path\n", .{});
    }

    try bw.flush(); // don't forget to flush!
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
