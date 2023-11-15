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

/// Internal use only. Looks up a field from a type-info struct.
inline fn UnsafeFieldLookup(comptime type_info: anytype, comptime lookup_name: []const u8) LookupError!type {
    comptime {
        if (type_info.fields.len == 0) return LookupError.TypeHasNoFields;

        for (type_info.fields) |field| {
            if (std.mem.eql(u8, field.name, lookup_name)) return field.type;
        }

        // If we're here, we haven't found it
        return LookupError.NotFound;
    }
}

/// Internal use only. Looks up a declaration from a type-info struct.
inline fn UnsafeDeclarationLookup(comptime from: type, comptime type_info: anytype, comptime lookup_name: []const u8) LookupError!type {
    comptime {
        if (type_info.decls.len == 0) return LookupError.TypeHasNoDeclarations;

        for (type_info.decls) |decl| {
            if (std.mem.eql(u8, decl.name, lookup_name)) return @TypeOf(@field(from, lookup_name));
        }

        // If we're here, we haven't found it
        return LookupError.NotFound;
    }
}

/// Internal use only. Looks up a field or declaraton from a type-info struct.
inline fn UnsafeAnyLookup(comptime from: type, comptime type_info: anytype, comptime lookup_name: []const u8) LookupError!type {
    comptime {
        if (type_info.fields.len == 0 and type_info.decls.len == 0) return LookupError.TypeHasNoFieldsOrDeclarations;

        for (type_info.fields) |field| {
            if (std.mem.eql(u8, field.name, lookup_name)) return field.type;
        }

        for (type_info.decls) |decl| {
            if (std.mem.eql(u8, decl.name, lookup_name)) return @TypeOf(@field(from, lookup_name));
        }

        // If we're here, we haven't found it
        return LookupError.NotFound;
    }
}

// Internal use only. Creates a tuple type for the enum look-up result (used for .Field and .Any lookups on enums)
pub fn EnumLookupResult(comptime from: type) type {
    return struct { field: ?from, decl: ?type };
}

/// Internal use only. Looks up a field from a type-info struct. Used for enums
inline fn UnsafeEnumFieldLookup(comptime from: type, comptime type_info: anytype, comptime lookup_name: []const u8) LookupError!from {
    comptime {
        if (type_info.fields.len == 0) return LookupError.TypeHasNoFields;

        for (type_info.fields) |field| {
            if (std.mem.eql(u8, field.name, lookup_name)) return @enumFromInt(field.value);
        }

        // If we're here, we haven't found it
        return LookupError.NotFound;
    }
}

/// Internal use only. Looks up a field or declaraton from a type-info struct. Used for enums.
inline fn UnsafeEnumAnyLookup(comptime from: type, comptime type_info: anytype, comptime lookup_name: []const u8) LookupError!EnumLookupResult(from) {
    comptime {
        const ResultType = EnumLookupResult(from);

        if (type_info.fields.len == 0 and type_info.decls.len == 0) return LookupError.TypeHasNoFieldsOrDeclarations;

        for (type_info.fields) |field| {
            if (std.mem.eql(u8, field.name, lookup_name)) return ResultType{ .field = @enumFromInt(field.value), .decl = null };
        }

        for (type_info.decls) |decl| {
            if (std.mem.eql(u8, decl.name, lookup_name)) return ResultType{ .field = null, .decl = @TypeOf(@field(from, lookup_name)) };
        }

        // If we're here, we haven't found it
        return LookupError.NotFound;
    }
}

/// Internal use only. Looks up parameters from structs and unions.
inline fn UnsafeLookup(comptime from: type, comptime type_info: anytype, comptime lookup_name: []const u8, comptime lookup_mode: LookupMode) LookupError!type {
    comptime {
        switch (lookup_mode) {
            // Search for a field
            .Field => {
                return UnsafeFieldLookup(type_info, lookup_name);
            },
            // Search for a declaration
            .Declaration => {
                return UnsafeDeclarationLookup(from, type_info, lookup_name);
            },
            // Search for either
            .Any => {
                return UnsafeAnyLookup(from, type_info, lookup_name);
            },
        }
    }
}

/// Internal use only. Looks up parameters from enums.
inline fn UnsafeEnumLookup(comptime from: type, comptime type_info: anytype, comptime lookup_name: []const u8, comptime lookup_mode: LookupMode) switch (lookup_mode) {
    .Field => LookupError!from,
    .Declaration => LookupError!type,
    .Any => LookupError!EnumLookupResult(from),
} {
    comptime {
        switch (lookup_mode) {
            // Search for a field
            .Field => {
                return UnsafeEnumFieldLookup(from, type_info, lookup_name);
            },
            // Search for a declaration
            .Declaration => {
                return UnsafeDeclarationLookup(from, type_info, lookup_name);
            },
            // Search for either
            .Any => {
                return UnsafeEnumAnyLookup(from, type_info, lookup_name);
            },
        }
    }
}

/// Tries to find a field or declaration given a name and a specified look-up mode
/// Returns the type of the field/declaration if found, otherwise errors with details.
pub fn FindInType(comptime from: type, comptime lookup_name: []const u8, comptime lookup_mode: LookupMode) switch (@typeInfo(from)) {
    .Enum => switch (lookup_mode) {
        .Field => LookupError!from,
        .Declaration => LookupError!type,
        .Any => LookupError!EnumLookupResult(from),
    },
    else => LookupError!type,
} {
    switch (@typeInfo(from)) {
        // Structs can have both fields and declarations
        .Struct => |struct_info| {
            return UnsafeLookup(from, struct_info, lookup_name, lookup_mode);
        },
        .Union => |uni_info| {
            return UnsafeLookup(from, uni_info, lookup_name, lookup_mode);
        },
        .Enum => |enu_info| {
            return UnsafeEnumLookup(from, enu_info, lookup_name, lookup_mode);
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
