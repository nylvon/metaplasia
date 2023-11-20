/// Metaplasia Common Utils
/// ©2023 Cristian Vasilache (NNCV / Nylvon)
///
/// Common functionality shared across the project.
pub const Common = @This();
const std = @import("std");

/// Restricts look-up to only fields or declarations, or does not restrict at all.
/// If Any is selected, fields are prioritised over declarations in the look-up order.
pub const LookupMode = enum { Field, Declaration, Any };

pub const LookupError = error{
    InvalidType,
    NotFound,
    TypeHasNoFields,
    TypeHasNoDeclarations,
    TypeHasNoFieldsOrDeclarations,
};

/// Contains the type that the declaration was gotten from as well as the declaration
pub const FullDeclaration = struct {
    decl: std.builtin.Type.Declaration,
    type: type,
};

/// Contains the type that the enum field was gotten from as well as the enum field
pub const FullEnumField = struct {
    field: std.builtin.Type.EnumField,
    type: type,
};

/// A Type Item is a part of a type, it is a wrapper over
/// fields and declarations of all types
pub const TypeItem = union {
    // NOTE: Should be kept up to date with the language specification.
    Declaration: FullDeclaration,
    StructField: std.builtin.Type.StructField,
    EnumField: FullEnumField,
    UnionField: std.builtin.Type.UnionField,

    /// Returns the type of the type item
    pub fn GetType(comptime self: @This()) type {
        switch (std.meta.activeTag(self)) {
            .Declaration => |d| return @TypeOf(@field(d.type, d.decl.name)),
            .StructField => |sf| return sf.type,
            .EnumField => |ef| return ef.type,
            .UnionField => |uf| return uf.type,
        }
    }
};

/// Internal use only. Looks up a field from a type-info struct.
inline fn UnsafeFieldLookup(comptime target: type, comptime lookup_name: []const u8) LookupError!TypeItem {
    comptime {
        const type_info = @TypeOf(target);

        if (type_info.fields.len == 0) return LookupError.TypeHasNoFields;

        for (type_info.fields) |field| {
            if (std.mem.eql(u8, field.name, lookup_name)) {
                switch (type_info) {
                    .Struct => return TypeItem{ .StructField = field },
                    .Enum => return TypeItem{ .EnumField = FullEnumField{ .field = field, .type = target } },
                    .Union => return TypeItem{ .UnionField = field },
                    else => @compileError("Please do not use this function on its own, as the checks for its usage are done outside its context!"),
                }
            }
        }

        // If we're here, we haven't found it
        return LookupError.NotFound;
    }
}

/// Internal use only. Looks up a declaration from a type-info struct.
inline fn UnsafeDeclarationLookup(comptime target: type, comptime lookup_name: []const u8) LookupError!TypeItem {
    comptime {
        const type_info = @TypeOf(target);

        if (type_info.decls.len == 0) return LookupError.TypeHasNoDeclarations;

        for (type_info.decls) |decl| {
            if (std.mem.eql(u8, decl.name, lookup_name)) return TypeItem{ .Declaration = FullDeclaration{ .decl = decl, .type = type } };
        }

        // If we're here, we haven't found it
        return LookupError.NotFound;
    }
}

/// Internal use only. Looks up a field or declaraton from a type-info struct.
inline fn UnsafeAnyLookup(comptime type_info: anytype, comptime lookup_name: []const u8) LookupError!TypeItem {
    comptime {
        if (type_info.fields.len == 0 and type_info.decls.len == 0) return LookupError.TypeHasNoFieldsOrDeclarations;

        for (type_info.fields) |field| {
            if (std.mem.eql(u8, field.name, lookup_name)) {
                switch (@typeInfo(@TypeOf(type_info))) {
                    .Struct => return TypeItem{ .StructField = field },
                    .Enum => return TypeItem{ .EnumField = field },
                    .Union => return TypeItem{ .UnionField = field },
                    else => @compileError("Please do not use this function on its own, as the checks for its usage are done outside its context!"),
                }
            }
        }

        for (type_info.decls) |decl| {
            if (std.mem.eql(u8, decl.name, lookup_name)) return TypeItem{ .Declaration = decl };
        }

        // If we're here, we haven't found it
        return LookupError.NotFound;
    }
}

/// Internal use only. Looks up parameters from structs and unions.
inline fn UnsafeLookup(comptime type_info: anytype, comptime lookup_name: []const u8, comptime lookup_mode: LookupMode) LookupError!TypeItem {
    comptime {
        switch (lookup_mode) {
            // Search for a field
            .Field => {
                return UnsafeFieldLookup(type_info, lookup_name);
            },
            // Search for a declaration
            .Declaration => {
                return UnsafeDeclarationLookup(type_info, lookup_name);
            },
            // Search for either
            .Any => {
                return UnsafeAnyLookup(type_info, lookup_name);
            },
        }
    }
}

/// Tries to find a field or declaration given a name and a specified look-up mode
/// Returns the type of the field/declaration if found, otherwise errors with details.
pub fn FindInType(comptime from: type, comptime lookup_name: []const u8, comptime lookup_mode: LookupMode) LookupError!TypeItem {
    switch (@typeInfo(from)) {
        // Structs can have both fields and declarations
        .Struct => |struct_info| {
            return UnsafeLookup(struct_info, lookup_name, lookup_mode);
        },
        .Union => |uni_info| {
            return UnsafeLookup(uni_info, lookup_name, lookup_mode);
        },
        .Enum => |enu_info| {
            return UnsafeLookup(enu_info, lookup_name, lookup_mode);
        },
        .Pointer => |ptr_info| {
            return FindInType(ptr_info.child, lookup_name, lookup_mode);
        },
        .Vector => |vec_info| {
            return FindInType(vec_info.child, lookup_name, lookup_mode);
        },
        .Optional => |opt_info| {
            return FindInType(opt_info.child, lookup_name, lookup_mode);
        },
        .Array => |arr_info| {
            return FindInType(arr_info.child, lookup_name, lookup_mode);
        },
        .ErrorUnion => |eru_info| {
            return FindInType(eru_info.payload, lookup_name, lookup_mode);
        },
        else => return LookupError.InvalidType,
    }
}
