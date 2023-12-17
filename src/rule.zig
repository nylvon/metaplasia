/// Metaplasia Rule
/// ©2023 Cristian Vasilache (NNCV / Nylvon)
///
/// A rule is a constraint for a type.
pub const Rule = Rule_internal;
const Common = @import("common.zig");
const std = @import("std");

/// All base rules
pub const Kind = enum {
    /// Look-up must be within the type definition.
    IsInType,

    /// Look-up must be of a given type.
    IsType,

    /// Look-up must be a function type.
    IsFunction,

    /// Look-up must be a variable.
    IsVariable,

    /// Look-up must be a constant.
    IsConstant,

    /// Custom Rules? (?)
    CustomDefinition,
};

/// An all-encompassing wrapper for rules for types.
/// All rules must validate the IRule interface.
/// TODO: When typechecking is implemented, make sure all
///       rules are checked against it (and pass).
const Rule_internal = union(Kind) {
    /// Checks whether a field or declaration is within the definition of the type.
    IsInType: IsInTypeRule,

    /// Checks whether a field or declaration is of a specified type within the definition of the type.
    IsType: IsTypeRule,

    /// Checks whether a field or declaration is a function within the definition of the type.
    IsFunction: IsFunctionRule,

    /// Checks whether a field or declaration is variable within the definition of the type.
    IsVariable: IsVariableRule,

    /// Checks whether a field or declaration is constant within the definition of the type.
    IsConstant: IsConstantRule,

    /// Checks according to the custom checking function and custom rule data.
    CustomDefinition: CustomDefinitionRule,

    //
    // Rule operations below
    //

    /// Calls the rule descriptor's 'Check' function.
    pub fn Check(comptime self: @This(), comptime target: type) !bool {
        switch (self) {
            // NOTE: "ir" stands for "inner rule".
            .IsInType => |ir| return ir.Check(target),
            .IsType => |ir| return ir.Check(target),
            .IsFunction => |ir| return ir.Check(target),
            .IsVariable => |ir| return ir.Check(target),
            .IsConstant => |ir| return ir.Check(target),
            .CustomDefinition => |ir| return ir.Check(target),
        }
    }

    //
    // Rule types below
    //

    pub const IsInTypeRule = struct {
        lookup_data: Common.LookupData,

        pub fn Check(comptime self: @This(), comptime target: type) !bool {
            _ = Common.FindInType(target, self.lookup_data.lookup_name, self.lookup_data.lookup_mode) catch |err| {
                if (err == Common.LookupError.NotFound) {
                    return false;
                } else return err;
            };
            return true;
        }
    };

    pub const IsTypeRule = struct {
        lookup_data: Common.LookupData,
        lookup_type: type,

        pub fn Check(comptime self: @This(), comptime target: type) !bool {
            const lookup = try Common.FindInType(target, self.lookup_data.lookup_name, self.lookup_data.lookup_mode);
            return lookup.GetType() == self.lookup_type;
        }
    };

    pub const IsFunctionRule = struct {
        lookup_data: Common.LookupData,

        pub fn Check(comptime self: @This(), comptime target: type) !bool {
            const lookup = try Common.FindInType(target, self.lookup_data.lookup_name, self.lookup_data.lookup_mode);
            switch (@typeInfo(lookup.GetType())) {
                .Fn => return true,
                else => return false,
            }
            // Below may do the same thing as above, I can't remember if it is the exact same, though.
            // return std.meta.activeTag(@typeInfo(lookup.GetType())) == .Fn;
        }
    };

    pub const IsVariableRule = struct {
        lookup_data: Common.LookupData,

        pub fn Check(comptime self: @This(), comptime target: type) !bool {
            const lookup = try Common.FindInType(target, self.lookup_data.lookup_name, self.lookup_data.lookup_mode);
            return lookup.GetIsVariable();
        }
    };

    pub const IsConstantRule = struct {
        lookup_data: Common.LookupData,

        pub fn Check(comptime self: @This(), comptime target: type) !bool {
            const lookup = try Common.FindInType(target, self.lookup_data.lookup_name, self.lookup_data.lookup_mode);
            return lookup.GetIsConstant();
        }
    };

    pub const CustomDefinitionRule = struct {
        check_fn: *const fn (comptime type, comptime *anyopaque) anyerror!bool,
        rule_data: *anyopaque,

        pub fn Check(comptime self: @This(), comptime target: type) !bool {
            return self.check_fn(target, self.rule_data);
        }
    };
};
