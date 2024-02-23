const std = @import("std");
const toml = @import("toml-zig");
const task = @import("task.zig");
const schema = @import("schema.zig");
const cFs = @import("fs.zig");
const fs = std.fs;

const ParserError = error{
    NotFound,
};

const CustomParser = struct {
    tokenstream: *toml.value.TokenStream,
    alloc: std.mem.Allocator,

    fn init(body: []const u8, alloc: std.mem.Allocator) !CustomParser {
        std.debug.print("1 getTask {s}\n", .{body});
        var tokenstream = toml.value.TokenStream.init(body);
        return CustomParser{ .tokenstream = &tokenstream, .alloc = alloc };
    }

    fn deinit(self: CustomParser) void {
        _ = self;
    }
};

pub const Config = struct {
    config: CustomParser,
    alloc: std.mem.Allocator,
    readFile: []const u8,

    pub fn init(configFile: cFs.File, alloc: std.mem.Allocator) !Config {
        const readFile = try configFile.file.readToEndAlloc(alloc, 1024);
        return Config{
            .config = try CustomParser.init(readFile, alloc),
            .alloc = alloc,
            .readFile = readFile,
        };
    }

    pub fn deinit(self: Config) void {
        self.config.deinit();
        self.alloc.free(self.readFile);
    }

    pub fn getTask(self: *const Config, taskName: []const u8) !task.Task {
        const tokenstream = self.config.tokenstream;
        var value = tokenstream.get(self.alloc, taskName) catch |err| {
            std.debug.print("getTask error {}\n", .{err});
            return ParserError.NotFound;
        };
        defer value.deinit(self.alloc);
        std.debug.print("getTask {?}\n", .{value});
        return task.Task{};
    }
};
