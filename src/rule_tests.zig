/// Metaplasia Rule Tests
/// ©2023 Cristian Vasilache (NNCV / Nylvon)
///
/// Provides an exhaustive test suite for the
/// Rule part of the Metaplasia library.
///
/// Each test name is formatted as follows:
/// "[FeatureName] [Scenario]"
pub const RuleTests = @This();
const Common = @import("common.zig");
const FindField = Common.FindField;
const FindDeclaration = Common.FindDeclaration;
const FindAny = Common.FindAny;
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

test "Interfaces at last" {
    const test_type = struct {
        a: i32,
        b: i32,
    };

    // A simple interface definition
    const HasBoth =
        Blank()
        .And(IsInType(FindField("a")))
        .And(IsInType(FindField("b")));

    const HasEither =
        Blank()
        .Or(IsInType(FindField("a")))
        .Or(IsInType(FindField("b")));

    const checkBoth = try HasBoth.Check(test_type);
    const checkEither = try HasEither.Check(test_type);
    try expect(checkBoth);
    try expect(checkEither);

    const test_type_2 = struct {
        a: i32,
    };

    const checkBoth2 = try HasBoth.Check(test_type_2);
    const checkEither2 = try HasEither.Check(test_type_2);
    try expect(!checkBoth2);
    try expect(checkEither2);

    const test_type_3 = struct {};

    try expectError(Common.LookupError.TypeHasNoFields, HasBoth.Check(test_type_3));
}
