/// Metaplasia Common Utils
/// ©2023 Cristian Vasilache (NNCV / Nylvon)
///
/// Common functionality shared across the project.
pub const Common = @This();
const std = @import("std");

/// Small container for look-ups.
/// TODO: Refactor using this type.
pub const LookupData = struct {
    lookup_name: []const u8,
    lookup_mode: LookupMode,
};

/// Restricts look-up to only fields or declarations, or does not restrict at all.
/// If Any is selected, fields are prioritised over declarations in the look-up order.
pub const LookupMode = enum { Field, Declaration, Any };

/// Used by FindInType to detail why the function call failed.
pub const LookupError = error{
    InvalidType,
    NotFound,
    TypeHasNoFields,
    TypeHasNoDeclarations,
    TypeHasNoFieldsOrDeclarations,
};

/// Contains the type that the declaration was gotten from as well as the declaration.
pub const FullDeclaration = struct {
    decl: std.builtin.Type.Declaration,
    type: type,
    is_const: bool,
};

/// Contains the type that the enum field was gotten from as well as the enum field.
pub const FullEnumField = struct {
    field: std.builtin.Type.EnumField,
    type: type,
};

/// This enum is used to identify the active part of the
/// TypeItem union wrapper.
pub const TypeItemKind = enum {
    Declaration,
    StructField,
    EnumField,
    UnionField,
};

/// The mutability of a TypeItem entity.
pub const TypeItemMutability = enum { Variable, Constant };

/// A Type Item is a part of a type, it is a wrapper over
/// fields and declarations of all types.
pub const TypeItem = union(TypeItemKind) {
    // NOTE: Should be kept up to date with the language specification.
    Declaration: FullDeclaration,
    StructField: std.builtin.Type.StructField,
    EnumField: FullEnumField,
    UnionField: std.builtin.Type.UnionField,

    /// The error set that can be returned by the functions of the TypeItem wrapper.
    pub const Error = error{
        InvalidType,
    };

    /// Returns the type of the entity described.
    pub fn GetType(comptime self: @This()) type {
        switch (self) {
            .Declaration => |d| return @TypeOf(@field(d.type, d.decl.name)),
            .StructField => |sf| return sf.type,
            .EnumField => |ef| return ef.type,
            .UnionField => |uf| return uf.type,
        }
    }

    /// Returns the name of the entity described.
    pub fn GetName(comptime self: @This()) []const u8 {
        switch (self) {
            .Declaration => |d| return d.decl.name,
            .StructField => |sf| return sf.name,
            .EnumField => |ef| return ef.field.name,
            .UnionField => |uf| return uf.name,
        }
    }

    /// Returns the default value of the entity described.
    /// If the entity doesn't have a default value, null will be returned.
    /// If the entity cannot have a default value, an error will be returned.
    pub fn GetDefaultValue(comptime self: @This()) switch (self) {
        .StructField => ?*const anyopaque,
        else => TypeItem.Error,
    } {
        switch (self) {
            .StructField => |sf| return sf.default_value,
            else => return TypeItem.Error.InvalidType,
        }
    }

    /// Returns whether the entity described has a constant value.
    pub fn GetIsConstant(comptime self: @This()) bool {
        switch (self) {
            .Declaration => |d| return d.is_const,
            else => return false,
        }
    }

    /// Returns whether the entity described has a non-constant value.
    pub fn GetIsVariable(comptime self: @This()) bool {
        return !self.GetIsConstant();
    }
};

/// Internal use only. Looks up a field from a type-info struct.
inline fn UnsafeFieldLookup(comptime target: type, comptime lookup_name: []const u8) LookupError!TypeItem {
    comptime {
        const type_info = switch (@typeInfo(target)) {
            .Struct => |s| s,
            .Enum => |e| e,
            .Union => |u| u,
            else => unreachable,
        };

        if (type_info.fields.len == 0) return LookupError.TypeHasNoFields;

        for (type_info.fields) |field| {
            if (std.mem.eql(u8, field.name, lookup_name)) {
                switch (@typeInfo(target)) {
                    .Struct => return TypeItem{ .StructField = field },
                    .Enum => return TypeItem{ .EnumField = FullEnumField{ .field = field, .type = target } },
                    .Union => return TypeItem{ .UnionField = field },
                    else => unreachable,
                }
            }
        }

        // If we're here, we haven't found it.
        return LookupError.NotFound;
    }
}

/// Internal use only. Looks up a declaration from a type-info struct.
inline fn UnsafeDeclarationLookup(comptime target: type, comptime lookup_name: []const u8) LookupError!TypeItem {
    comptime {
        const type_info = switch (@typeInfo(target)) {
            .Struct => |s| s,
            .Enum => |e| e,
            .Union => |u| u,
            else => unreachable,
        };

        if (type_info.decls.len == 0) return LookupError.TypeHasNoDeclarations;

        for (type_info.decls) |decl| {
            if (std.mem.eql(u8, decl.name, lookup_name))
                return TypeItem{ .Declaration = FullDeclaration{
                    .decl = decl,
                    .type = target,
                    .is_const = @typeInfo(@TypeOf(&@field(target, decl.name))).Pointer.is_const,
                } };
        }

        // If we're here, we haven't found it.
        return LookupError.NotFound;
    }
}

/// Internal use only. Looks up a field or declaraton from a type-info struct.
inline fn UnsafeAnyLookup(comptime target: type, comptime lookup_name: []const u8) LookupError!TypeItem {
    comptime {
        const type_info = switch (@typeInfo(target)) {
            .Struct => |s| s,
            .Enum => |e| e,
            .Union => |u| u,
            else => unreachable,
        };

        if (type_info.fields.len == 0 and type_info.decls.len == 0) return LookupError.TypeHasNoFieldsOrDeclarations;

        for (type_info.fields) |field| {
            if (std.mem.eql(u8, field.name, lookup_name)) {
                switch (@typeInfo(target)) {
                    .Struct => return TypeItem{ .StructField = field },
                    .Enum => return TypeItem{ .EnumField = FullEnumField{ .field = field, .type = target } },
                    .Union => return TypeItem{ .UnionField = field },
                    else => @compileError("Please do not use this function on its own, as this function does not do any checks on the inputs!"),
                }
            }
        }

        for (type_info.decls) |decl| {
            if (std.mem.eql(u8, decl.name, lookup_name))
                return TypeItem{ .Declaration = FullDeclaration{
                    .decl = decl,
                    .type = target,
                    .is_const = @typeInfo(@TypeOf(&@field(target, decl.name))).Pointer.is_const,
                } };
        }

        // If we're here, we haven't found it.
        return LookupError.NotFound;
    }
}

/// Internal use only. Looks up parameters from structs and unions.
inline fn UnsafeLookup(comptime target: type, comptime lookup_name: []const u8, comptime lookup_mode: LookupMode) LookupError!TypeItem {
    comptime {
        switch (lookup_mode) {
            // Search for a field
            .Field => {
                return UnsafeFieldLookup(target, lookup_name);
            },
            // Search for a declaration
            .Declaration => {
                return UnsafeDeclarationLookup(target, lookup_name);
            },
            // Search for either
            .Any => {
                return UnsafeAnyLookup(target, lookup_name);
            },
        }
    }
}

/// Tries to find a field or declaration given a name and a specified look-up mode.
/// Returns the type of the field/declaration if found, otherwise errors with details.
pub fn FindInType(comptime from: type, comptime lookup_name: []const u8, comptime lookup_mode: LookupMode) LookupError!TypeItem {
    switch (@typeInfo(from)) {
        // Structs can have both fields and declarations
        .Struct, .Union, .Enum => {
            return UnsafeLookup(from, lookup_name, lookup_mode);
        },
        .Pointer, .Vector, .Optional, .Array, .ErrorUnion => {
            return FindInType(GetBaseType(from), lookup_name, lookup_mode);
        },
        else => return LookupError.InvalidType,
    }
}

/// Gets the base type of any pointer/vector/array/etc type.
pub fn GetBaseType(comptime from: type) type {
    switch (@typeInfo(from)) {
        .Pointer => |ptr| return GetBaseType(ptr.child),
        .Vector => |vec| return GetBaseType(vec.child),
        .Optional => |opt| return GetBaseType(opt.child),
        .Array => |arr| return GetBaseType(arr.child),
        .ErrorUnion => |eru| return GetBaseType(eru.payload),
        else => return from,
    }
}
