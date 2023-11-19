/// Metaplasia Rule
/// ©2023 Cristian Vasilache (NNCV / Nylvon)
///
/// A rule is a constraint for a type.
pub const Rule = @This();
const Common = @import("common.zig");
const std = @import("std");

/// All base rules
pub const Type = enum {
    IsField,
    IsDeclaration,
    IsInType, // Either as a field or as a declaration
    IsType,
    IsVariable,
    IsConstant,
};

/// Dictates how a rule should be enforced
pub const Strictness = enum { Required, NotRequired };

type: Type,
name: []const u8,
strictness: Strictness,

/// Checks whether a type matches a rule
pub fn Check(comptime self: *const Rule, comptime target: type) !bool {
    switch (self.type) {
        .IsField => {
            // If there's no types, it'll return false.
            // If there's another error, it'll return it.
            Common.FindInType(target, self.name, .Field) catch |err| {
                switch (err) {
                    .NotFound => return false,
                    else => return err,
                }
            };

            // If we're here, it returned the type, which implies a successful look-up.
            return true;
        },
        .IsDeclaration => {
            Common.FindInType(target, self.name, .Declaration) catch |err| {
                switch (err) {
                    .NotFound => return false,
                    else => return err,
                }
            };

            return true;
        },
        .IsInType => {
            Common.FindInType(target, self.name, .Any) catch |err| {
                switch (err) {
                    .NotFound => return false,
                    else => return err,
                }
            };

            return true;
        },
        else => return error.NotImplemented, // TODO: Implement the rest
        // .IsConstant, .IsVariable require a different function that returns data about the field/declaration
    }
}
