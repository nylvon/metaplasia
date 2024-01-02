/// Metaplasia Rule
/// ©2023 Cristian Vasilache (NNCV / Nylvon)
///
/// A rule is a function that validates a constraint on a type.
/// A ruleset is a set of rules that validate multiple constraints in any manner.
pub const Rule = @This();
const Common = @import("common.zig");
const std = @import("std");

/// Similar to std.meta.trait's TraitFn, but it can also return errors.
/// Useful for debugging why something doesn't validate a rule.
pub const RuleFn = fn (comptime type) anyerror!bool;

/// A rule set is a decision tree that upon traversal determines whether
/// a type meets certain criteria, and if not, returns all the errors.
pub const RuleSet = struct {
    rule: ?RuleFn,
    children: ?[]const RuleSet,
    link: Link,
    outcome: ?anyerror!bool,

    /// Determines how this rule is linked with the previous rule.
    pub const Link = enum {
        Root, // Reserved for the root rule-set.
        And, // Previous rule is valid if this one is also valid.
        Or, // Previous rule may be valid if this one isn't.
        // TODO: Add more links.
        // NOTE: Is it necessary?
    };

    pub fn CheckChildren(comptime self: *const RuleSet, comptime target: type) anyerror!bool {
        if (self.children) |children| {
            var ok = true;
            inline for (children) |*child| {
                const child_outcome = try child.Check(target);
                switch (child.link) {
                    .And => {
                        ok = ok and child_outcome;
                    },
                    .Or => {
                        ok = ok or child_outcome;
                    },
                    .Root => {
                        return error.ChildIsRoot;
                    },
                }
            }
            return ok;
        } else return error.NoChildren;
    }

    pub fn Check(comptime self: *const RuleSet, comptime target: type) anyerror!bool {
        // If there is no rule, it passes the check, otherwise evaluate.
        const ok_rule = if (self.rule) |r| try r(target) else true;
        const ok_children = self.CheckChildren(target) catch |err| {
            if (err == error.NoChildren) {
                // If there's no children, just return the rule's result.
                return ok_rule;
            } else return err;
        };
        // If we're here, ok_children is a bool.
        // A root node is an "and" node with children.
        // self.outcome = ok_children and ok_rule;
        return ok_children and ok_rule;
    }

    //
    //  Rule-set generation utilities
    //

    /// Returns a blank rule-set.
    /// Used to return a root rule-set node.
    pub fn Blank() RuleSet {
        return RuleSet{
            .rule = null,
            .children = null,
            .link = .Root,
            .outcome = null,
        };
    }

    /// Returns an insular rule-set from a rule function.
    pub fn From(comptime rule: RuleFn, comptime link: RuleSet.Link) RuleSet {
        return RuleSet{
            .rule = rule,
            .children = null,
            .link = link,
            .outcome = null,
        };
    }

    /// Adds the specified rule-set to the current one as a child of it.
    /// Returns a pointer to the current rule-set after modifying it.
    pub fn Inject(comptime self: *const RuleSet, comptime ruleset: RuleSet) *const RuleSet {
        if (self.children != null) {
            const new_ruleset = RuleSet{
                //
                .rule = self.rule,
                .link = self.link,
                .outcome = self.outcome,
                .children = self.children.? ++ &[1]RuleSet{ruleset},
            };
            return &new_ruleset;
        } else {
            const new_ruleset = RuleSet{
                //
                .rule = self.rule,
                .link = self.link,
                .outcome = self.outcome,
                .children = &[1]RuleSet{ruleset},
            };
            return &new_ruleset;
            // self.children = [1]RuleSet{ruleset};
            // var new_ruleset = RuleSet{ .rule = self.rule, .link = self.link, .outcome = self.outcome, .children = @constCast(&[1]RuleSet{ruleset}) };
            // return &new_ruleset;
        }
    }

    /// Adds another rule with an "and" relationship to the current rule-set.
    /// Returns a pointer to the current rule-set after modifying it.
    pub fn And(comptime self: *const RuleSet, comptime rule: RuleFn) *const RuleSet {
        const new_ruleset = From(rule, .And);
        return self.Inject(new_ruleset);
    }

    /// Adds another rule with an "or" relationship to the current rule-set.
    /// Returns a pointer to the current rule-set after modifying it.
    pub fn Or(comptime self: *const RuleSet, comptime rule: RuleFn) *const RuleSet {
        const new_ruleset = From(rule, .Or);
        return self.Inject(new_ruleset);
    }

    /// Prints the ruleset as a string
    pub fn Print(comptime self: *const RuleSet, comptime index: usize) []const u8 {
        comptime var pad: []const u8 = "";
        comptime {
            for (0..index) |i| {
                _ = i;
                pad = pad ++ "\t";
            }
            switch (self.link) {
                .And => pad = pad ++ "AND",
                .Or => pad = pad ++ "OR",
                .Root => pad = pad ++ "ROOT",
            }
            pad = pad ++ "\n";
            if (self.children) |children| {
                for (children) |c| {
                    pad = pad ++ c.Print(index + 1);
                }
            }
        }
        return pad;
    }
};

//
//  Basic rules
//

/// Checks whether a looked-up member is inside a type.
/// eg: Whether a struct has a member "check" that is a declaration.
pub fn IsInType(comptime lookup_data: Common.LookupData) RuleFn {
    return struct {
        pub fn rule(comptime target: type) anyerror!bool {
            _ = Common.FindInType(target, lookup_data.lookup_name, lookup_data.lookup_mode) catch |err| {
                if (err == Common.LookupError.NotFound) {
                    return false;
                } else return err;
            };
            return true;
        }
    }.rule;
}

/// Checks whether a looked-up member is of a certain type.
/// eg: Whether a struct has a member "check" that is of "fn(void) void" type.
pub fn IsType(comptime lookup_data: Common.LookupData, comptime wanted_type: type) RuleFn {
    return struct {
        pub fn rule(comptime target: type) anyerror!bool {
            const lookup = try Common.FindInType(target, lookup_data.lookup_name, lookup_data.lookup_mode);
            return lookup.GetType() == wanted_type;
        }
    }.rule;
}

/// Checks whether a looked-up member is of a certain archetype.
/// eg: Whether a struct has a member "check" that is a function (.Fn archetype)
pub fn IsArchetype(comptime lookup_data: Common.LookupData, comptime archetype: std.meta.tags(std.builtin.Type)) RuleFn {
    return struct {
        pub fn rule(comptime target: type) anyerror!bool {
            const lookup = try Common.FindInType(target, lookup_data.lookup_name, lookup_data.lookup_mode);
            return std.meta.activeTag(@typeInfo(lookup.GetType())) == archetype;
        }
    }.rule;
}

/// Checks whether a looked-up member is of a function archetype
/// This is a specialised case of "IsArchetype".
pub fn IsFunction(comptime lookup_data: Common.LookupData) RuleFn {
    return struct {
        pub fn rule(comptime target: type) anyerror!bool {
            return IsArchetype(lookup_data, .Fn)(target);
        }
    }.rule;
}

/// Checks whether a looked-up member is variable.
/// eg: Whether a struct has a declaration "check" whose value can be changed.
pub fn IsVariable(comptime lookup_data: Common.LookupData) RuleFn {
    return struct {
        pub fn rule(comptime target: type) anyerror!bool {
            const lookup = try Common.FindInType(target, lookup_data.lookup_name, lookup_data.lookup_mode);
            return lookup.GetIsVariable();
        }
    }.rule;
}

/// Checks whether a looked-up member is constant.
/// eg: Whether a struct has a declaration "check" whose value can't be changed.
pub fn IsConstant(comptime lookup_data: Common.LookupData) RuleFn {
    return struct {
        pub fn rule(comptime target: type) anyerror!bool {
            const lookup = try Common.FindInType(target, lookup_data.lookup_name, lookup_data.lookup_mode);
            return lookup.GetIsConstant();
        }
    }.rule;
}
