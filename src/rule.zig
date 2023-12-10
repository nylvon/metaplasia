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

    /// Look-up must be within the definition of any types within the type definition.
    /// Depth for look-up is set, and filters are also set.
    IsInTypeMembers,

    /// Look-up must be of a given type.
    IsOfType,

    /// Look-up must be bound(?) within a given type set (Ints of any bits, etc).
    /// TODO: Rethink this.
    IsOfTypeKind,

    /// Look-up must be a function type.
    IsFunction,

    /// Look-up must be a variable.
    IsVariable,

    /// Look-up must be a constant.
    IsConstant,

    /// Look-up must be available at compile time.
    IsComptime,

    /// Custom Rules? (?)
    CustomDefinition,
};

/// An all-encompassing wrapper for rules for types.
/// All rules must validate the IRule interface.
/// TODO: When typechecking is implemented, make sure all
///       rules are checked against it (and pass).
const Rule_internal = union(Kind) {
    /// Checks whether a field or declaration is within the definition of the type.
    IsInType: struct {
        lookup_data: Common.LookupData,

        pub fn Check(comptime self: @This(), comptime target: type) !bool {
            _ = Common.FindInType(target, self.lookup_data.lookup_name, self.lookup_data.lookup_mode) catch |err| {
                if (err == Common.LookupError.NotFound) {
                    return false;
                } else return err;
            };
            return true;
        }
    },

    /// Checks whether a field or declaration is a function within the definition of the type.
    IsFunction: struct {
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
    },

    /// Checks whether a field or declaration is variable within the definition of the type.
    IsVariable: struct {
        lookup_data: Common.LookupData,

        pub fn Check(comptime self: @This(), comptime target: type) !bool {
            const lookup = try Common.FindInType(target, self.lookup_data.lookup_name, self.lookup_data.lookup_mode);
            const type_before = lookup.GetType();
            // If it didn't change, it wasn't constant.
            return type_before == @constCast(type_before);
        }
    },

    /// Checks whether a field or declaration is constant within the definition of the type.
    IsConstant: struct {
        lookup_data: Common.LookupData,

        pub fn Check(comptime self: @This(), comptime target: type) !bool {
            const lookup = try Common.FindInType(target, self.lookup_data.lookup_name, self.lookup_data.lookup_mode);
            const type_before = lookup.GetType();
            // If it became variable now, it means that it was constant before.
            return type_before != @constCast(type_before);
        }
    },

    /// Checks whether a field or declaration is available at compile time within the definition of the type.
    IsComptime: struct {
        lookup_data: Common.LookupData,

        pub fn Check(comptime self: @This(), comptime target: type) !bool {
            const lookup = try Common.FindInType(target, self.lookup_data.lookup_name, self.lookup_data.lookup_mode);
            _ = lookup;
            // TODO: Add GetIsComptime to TypeItem in Common
            return error.NotImplemented;
        }
    },

    /// Checks whether a field or declaration is of a specified type within the definition of the type.
    IsOfType: struct {
        lookup_data: Common.LookupData,
        lookup_type: type,

        pub fn Check(comptime self: @This(), comptime target: type) !bool {
            const lookup = try Common.FindInType(target, self.lookup_data.lookup_name, self.lookup_data.lookup_mode);
            return lookup.GetType() == self.lookup_type;
        }
    },

    /// Checks whether the given member is of a specific kind of types.
    /// (i.e. std.builtin.Type.Int of any bits)
    /// TODO: Re-think this.
    ///       Maybe we could pull it off with just some custom rules?
    IsOfTypeKind: struct {
        lookup_data: Common.LookupData,
        lookup_kind: std.builtin.Type,

        pub fn Check(comptime self: @This(), comptime target: type) !bool {
            _ = target;
            _ = self;
            // TODO: Come up with a proper definition for this rule.
            //       Maybe leave it as custom rules.
            return error.NotImplemented;
        }
    },

    /// Checks according to the custom definition given by a custom descriptor type.
    /// All custom descriptors must obey the rule definition interface IRuleDefinition.
    /// TODO: Define IRuleDefinition, and make sure all rules are checked against it.
    /// TODO: When interfaces are implemented, use an interface typechecker here.
    ///       (Or maybe somewhere else?).
    CustomDefinition: struct {
        definition: type,

        // Placeholder for interface typechecker.
        // (Will be replaced, of course)
        // TODO: Replace with something proper
        //       when typechecker is implemented.
        pub const InterfacePass: bool = false;

        pub fn Check(comptime self: @This(), comptime target: type) !bool {
            // Or maybe do the check here before returning?
            // TODO: Think about it.
            return self.definition.Check(target);
        }
    },
};

// NOTE: Below is obsolete code, which will get reworked into
//       the new framework above, or get removed completely.

// kind: Kind,
// name: []const u8,
// children: ?[]const Rule,

// /// Checks whether the children conditions match
// pub fn CheckChildren(comptime self: *const Rule, comptime target: type) !bool {
//     var checked = true;
//     if (self.children) |*children| {
//         for (children) |*c| {
//             checked &= c.Check(target);
//         }
//     }
//     return checked;
// }

// /// Checks whether a type matches a rule
// pub fn Check(comptime self: *const Rule, comptime target: type) !bool {
//     switch (self.kind) {
//         .IsField => {
//             // If there's no types, it'll return false.
//             // If there's another error, it'll return it.
//             _ = Common.FindInType(target, self.name, .Field) catch |err| {
//                 switch (err) {
//                     .NotFound => return false,
//                     else => return err,
//                 }
//             };

//             // TODO: Think of a better way to do this.
//             var checked = true;
//             if (self.children) |*children| {
//                 for (children) |*c| {
//                     checked &= c.Check(target);
//                 }
//             }
//             return checked;
//         },
//         .IsDeclaration => {
//             _ = Common.FindInType(target, self.name, .Declaration) catch |err| {
//                 switch (err) {
//                     .NotFound => return false,
//                     else => return err,
//                 }
//             };

//             return true;
//         },
//         .IsInType => {
//             _ = Common.FindInType(target, self.name, .Any) catch |err| {
//                 switch (err) {
//                     .NotFound => return false,
//                     else => return err,
//                 }
//             };

//             return true;
//         },
//         .IsFunction => {
//             const type_item = Common.FindInType(target, self.name, .Any) catch |err| {
//                 switch (err) {
//                     .NotFound => return false,
//                     else => return err,
//                 }
//             };

//             const info = @typeInfo(type_item.GetType());
//             switch (info) {
//                 .Fn => return true,
//                 else => return false,
//             }
//         },
//         .IsVariable => {
//             const type_item = Common.FindInType(target, self.name, .Declaration) catch |err| {
//                 switch (err) {
//                     .NotFound => return false,
//                     else => return err,
//                 }
//             };

//             const decl_type = type_item.GetType();
//             if (@constCast(decl_type) == decl_type) {
//                 return true;
//             } else return false;
//         },
//         else => return error.NotImplemented, // TODO: Implement the rest
//     }
// }
