const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "Metaplasia",
        .root_source_file = b.path("src/metaplasia.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(lib);

    // COMMON
    const common_tests = b.addTest(.{
        .root_source_file = b.path("src/common_tests.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_common_tests = b.addRunArtifact(common_tests);

    const run_common_tests_step = b.step("test-common", "Run tests for the common utilities of this library.");
    run_common_tests_step.dependOn(&run_common_tests.step);

    // RULE
    const rule_tests = b.addTest(.{
        .root_source_file = b.path("src/rule_tests.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_rule_tests = b.addRunArtifact(rule_tests);

    const run_rule_tests_step = b.step("test-rule", "Run tests for the rule module of this library.");
    run_rule_tests_step.dependOn(run_common_tests_step);
    run_rule_tests_step.dependOn(&run_rule_tests.step);

    // METAPLASIA
    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(run_common_tests_step);
    test_step.dependOn(run_rule_tests_step);
}
