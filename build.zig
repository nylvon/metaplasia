const std = @import("std");

/// Creates a new test suite, makes a test step, and returns the test step.
pub fn add_tests(b: *std.Build, name: []const u8, desc: []const u8, path: []const u8, target: std.zig.CrossTarget, optimize: std.builtin.OptimizeMode) *std.Build.Step {
    const new_tests = b.addTest(.{
        .root_source_file = .{ .path = path },
        .target = target,
        .optimize = optimize,
    });

    const run_new_tests = b.addRunArtifact(new_tests);

    const new_tests_step = b.step(name, desc);
    new_tests_step.dependOn(&run_new_tests.step);

    return new_tests_step;
}

// TODO: Continue splitting the project into multiple sub-modules and implement this function.
// pub fn add_module(b: *std.Build, name: []const u8, test_desc: []const u8, path: []const u8, target: std.zig.CrossTarget, optimize: std.builtin.OptimizeMode) *std.Build.Step {
// const new_module = b.addModule // ???
// }

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "metaplasia",
        .root_source_file = .{ .path = "src/metaplasia.zig" },
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(lib);

    const test_step = b.step("test", "Run library tests");

    test_step.dependOn(add_tests(b, "common_tests", "Run the unit tests for the Common library.", "src/common_tests.zig", target, optimize));
    test_step.dependOn(add_tests(b, "rule_tests", "Run the unit tests for the Rule type.", "src/rule_tests.zig", target, optimize));
}
