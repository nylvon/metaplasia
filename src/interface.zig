/// Metaplasia Interface
/// ©2023 Cristian Vasilache (NNCV / Nylvon)
///
/// An interface is a set of independent rules that
/// must all be matched in order for a type to validate it.
pub const Interface = @This();
const Common = @import("common.zig");
const std = @import("std");
const RuleSet = @import("ruleset.zig").RuleSet;
const Rule = @import("rule.zig").Rule;

/// Creates a set of independent rules based off of the array of rules
/// that have been passed as a parameter.
pub fn Make(rules: []const Rule) RuleSet {
    var interface = RuleSet{
        .rules = [1]RuleSet.RuleNode{undefined} ** rules.len,
    };

    for (rules, 0..) |r, i| {
        interface.rules[i].children = null;
        interface.rules[i].mode = .Independent;
        interface.rules[i].rule = r;
    }
}
