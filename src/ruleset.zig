/// Metaplasia RuleSet
/// ©2023 Cristian Vasilache (NNCV / Nylvon)
///
/// A ruleset is a tree of rules with a specifier dictating
/// how the rules ought to be interpreted as a whole.
/// (i.e.: Some rules may depend on some other rules, whilst other may not)
pub const RuleSet = @This();
const Common = @import("common.zig");
const Rule = @import("rule.zig").Rule;
const std = @import("std");

/// How two rules can relate to eachother inside of a ruleset
pub const Relationship = enum {
    And,
    Or,
    Xor,
    Independent,
};

/// A rule node is a rule and a specifier.
/// The specifier marks that
pub const RuleNode = struct {
    rule: Rule,
    mode: Relationship,
    children: ?[]const Rule,
};

/// A ruleset has one or more rules,
/// Each rule can be a tree of rules.
rules: []const RuleNode,
