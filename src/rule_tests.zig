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
// NOTE: Crudely implemented just to test out whether the idea works.

test "Check" {
    const test_struct = struct {
        a: i32,
        pub const b: i64 = 10;
    };

    // Example valid look-up data.
    const lookup_a_any = LookupData{
        .lookup_name = "a",
        .lookup_mode = .Any,
    };

    // NOTE: All rules below assume a correct look-up.
    // TODO: Check behavior when look-up fails and ensure
    //       it returns the expected look-up error.
    // TODO: Tidy up everything, (maybe?) put it in a function.

    // IsInType
    const r_isintype = Rule{ .IsInType = .{
        .lookup_data = lookup_a_any,
    } };
    const o_isintype = try r_isintype.Check(test_struct);
    try expect(o_isintype == true);

    // NOTE: IsInTypeMembers is not checked right now
    //       because it is still being developed.

    // IsOfType
    const r_isoftype = Rule{ .IsOfType = .{
        .lookup_data = lookup_a_any,
        .lookup_type = i32,
    } };
    const o_isoftype = try r_isoftype.Check(test_struct);
    try expect(o_isoftype == true);

    // NOTE: IsOfTypeKind is not checked right now
    //       because it is still being developed.

    // IsFunction
    const r_isfunction = Rule{ .IsFunction = .{
        .lookup_data = lookup_a_any,
    } };
    const o_isfunction = try r_isfunction.Check(test_struct);
    try expect(o_isfunction == false);

    // TODO: Rework how IsVariable and IsConstant work.
    // TODO: Add "GetIsConstant" function to TypeItem in Common.
    //       -> It should return whether the member (field/decl)
    //       -> is constant or not.

    // IsVariable
    // const r_isvariable = Rule{ .IsVariable = .{
    //     .lookup_data = lookup_a_any,
    // } };
    // const o_isvariable = try r_isvariable.Check(test_struct);
    // try expect(o_isvariable == true);

    // IsConstant
    // const r_isconstant = Rule{ .IsConstant = .{
    //     .lookup_data = lookup_a_any,
    // } };
    // const o_isconstant = try r_isconstant.Check(test_struct);
    // try expect(o_isconstant == false);

    // NOTE: Add "GetIsComptime" function to TypeItem in Common.
    //       -> It should return if the item is available
    //       -> at compile time or not.
}
