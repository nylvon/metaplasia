/// Metaplasia Rule Tests
/// ©2023 Cristian Vasilache (NNCV / Nylvon)
///
/// Provides an exhaustive test suite for the
/// Rule part of the Metaplasia library.
///
/// Each test name is formatted as follows:
/// "[FeatureName] [Scenario]"
pub const RuleTests = @This();
const LookupData = @import("common.zig").LookupData;
const Rule = @import("rule.zig").Rule;
const std = @import("std");
const testing = std.testing;
const expect = testing.expect;
const expectEqual = testing.expectEqual;
const expectError = testing.expectError;
const activeTag = std.meta.activeTag;
const eql = std.mem.eql;

// Check tests

test "Check" {
    const test_struct = struct {
        a: i32,
        c: *const fn (void) void,
        pub const b: i64 = 10;
    };

    // Example valid look-up data.
    const lookup_a_any = LookupData{
        .lookup_name = "a",
        .lookup_mode = .Any,
    };
    const lookup_b_decl = LookupData{
        .lookup_name = "b",
        .lookup_mode = .Declaration,
    };
    const lookup_c_fn_field = LookupData{
        .lookup_name = "c",
        .lookup_mode = .Field,
    };

    // NOTE: All rules below assume a correct look-up.

    // IsInType
    const r_isintype = Rule{ .IsInType = .{
        .lookup_data = lookup_a_any,
    } };
    const o_isintype = try r_isintype.Check(test_struct);
    try expect(o_isintype == true);

    // IsOfType
    const r_isoftype = Rule{ .IsType = .{
        .lookup_data = lookup_a_any,
        .lookup_type = i32,
    } };
    const o_isoftype = try r_isoftype.Check(test_struct);
    try expect(o_isoftype == true);

    // IsFunction
    const r_isfunction = Rule{ .IsFunction = .{
        .lookup_data = lookup_a_any,
        .strict = false,
    } };
    const o_isfunction = try r_isfunction.Check(test_struct);
    try expect(o_isfunction == false);

    const r_isfunction_field = Rule{ .IsFunction = .{
        .lookup_data = lookup_c_fn_field,
        .strict = false,
    } };
    const o_isfunction_field = try r_isfunction_field.Check(test_struct);
    try expect(o_isfunction_field == true);

    const r_isfunction_field_strict = Rule{ .IsFunction = .{
        .lookup_data = lookup_c_fn_field,
        .strict = true,
    } };
    const o_isfunction_field_strict = try r_isfunction_field_strict.Check(test_struct);
    try expect(o_isfunction_field_strict == false);

    // IsVariable For Fields
    const r_isvariable_field = Rule{ .IsVariable = .{
        .lookup_data = lookup_a_any,
    } };
    const o_isvariable_field = try r_isvariable_field.Check(test_struct);
    try expect(o_isvariable_field == true);

    // IsConstant For Fields
    const r_isconstant_field = Rule{ .IsConstant = .{
        .lookup_data = lookup_a_any,
    } };
    const o_isconstant_field = try r_isconstant_field.Check(test_struct);
    try expect(o_isconstant_field == false);

    // IsVariable For Declarations
    const r_isvariable_decl = Rule{ .IsVariable = .{
        .lookup_data = lookup_b_decl,
    } };
    const o_isvariable_decl = try r_isvariable_decl.Check(test_struct);
    try expect(o_isvariable_decl == false);

    // IsConstant For Declarations
    const r_isconstant_decl = Rule{ .IsConstant = .{
        .lookup_data = lookup_b_decl,
    } };
    const o_isconstant_decl = try r_isconstant_decl.Check(test_struct);
    try expect(o_isconstant_decl == true);
}
