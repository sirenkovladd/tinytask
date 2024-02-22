const std = @import("std");
const coreFs = std.fs;

pub const File = struct {
    path: []const u8,
    file: coreFs.File,

    pub fn new(path: []const u8, file: coreFs.File) File {
        return File{ .path = path, .file = file };
    }
};

pub const FileSystem = struct {
    alloc: std.mem.Allocator,
    homePath: []const u8,

    pub fn init(al: std.mem.Allocator) !FileSystem {
        const homePath = std.os.getenv("HOME") orelse return error.@"HOME environment variable not set";

        return FileSystem{
            .alloc = al,
            .homePath = homePath,
        };
    }

    pub fn deinit(this: *const FileSystem) void {
        _ = this;
    }

    fn tryFindConfig(base_path: coreFs.Dir, name_config: [][]const u8) !?File {
        for (name_config) |name| {
            const entry: ?coreFs.File = base_path.openFile(name, .{}) catch |err| blk: {
                if (err == coreFs.File.OpenError.FileNotFound) {
                    break :blk null;
                }
                return err;
            };
            if (entry) |e| {
                return File.new(name, e);
            }
        }
        return null;
    }

    pub fn findConfig(this: *const FileSystem, base_path: []const u8, name_config: [][]const u8) !?File {
        var cwd = try coreFs.cwd().openDir(base_path, .{});
        var buf: [coreFs.MAX_PATH_BYTES]u8 = undefined;
        var curPath = try cwd.realpath(".", buf[0..]);
        while (true) {
            const entry = try FileSystem.tryFindConfig(cwd, name_config);
            if (entry) |e| {
                return File.new(try cwd.realpath(e.path, buf[0..]), e.file);
            }
            if (std.mem.eql(u8, curPath, this.homePath)) {
                break;
            } else if (curPath.len == 1) {
                break;
            }
            cwd = try cwd.openDir("..", .{});
            curPath = try cwd.realpath(".", buf[0..]);
        }
        return null;
    }
};
