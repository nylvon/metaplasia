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
const Rule = @import("rule.zig");
const RuleSet = Rule.RuleSet;
const Blank = RuleSet.Blank;
const From = RuleSet.From;
const Inject = RuleSet.Inject;
const And = RuleSet.And;
const Or = RuleSet.Or;
const IsInType = Rule.IsInType;
const IsType = Rule.IsType;
const IsArchetype = Rule.IsArchetype;
const IsFunction = Rule.IsFunction;
const IsVariable = Rule.IsVariable;
const IsConstant = Rule.IsConstant;
const std = @import("std");
const testing = std.testing;
const expect = testing.expect;
const expectEqual = testing.expectEqual;
const expectError = testing.expectError;
const activeTag = std.meta.activeTag;
const eql = std.mem.eql;

test "And" {
    const lookup_a = LookupData{ .lookup_mode = .Field, .lookup_name = "a" };
    const lookup_b = LookupData{ .lookup_mode = .Field, .lookup_name = "b" };

    const test_type = struct {
        a: i32,
        b: i32,
    };
    _ = test_type;

    const HasAB = Blank().And(IsInType(lookup_a))
        .And(IsInType(lookup_b));

    const msg = HasAB.Print(0);
    std.log.err("\n{s}", .{msg});
    try expectEqual(@TypeOf(HasAB), *const RuleSet);
}
