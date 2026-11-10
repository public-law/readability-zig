const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("readability", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const test_step = b.step("test", "Run tests");
    for ([_][]const u8{
        "tests/formulas.zig",
        "tests/utils.zig",
        "tests/integration.zig",
    }) |path| {
        const t = b.addTest(.{
            .root_module = b.createModule(.{
                .root_source_file = b.path(path),
                .target = target,
                .optimize = optimize,
                .imports = &.{
                    .{ .name = "readability", .module = mod },
                },
            }),
        });
        test_step.dependOn(&b.addRunArtifact(t).step);
    }
}
