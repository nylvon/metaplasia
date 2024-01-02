/// Metaplasia Common Tests
/// ©2023 Cristian Vasilache (NNCV / Nylvon)
///
/// Provides an exhaustive test suite for the common
/// functionality of the Metaplasia library.
///
/// Each test name is formatted as follows:
/// "[FeatureName] [Scenario]"
pub const CommonTests = @This();
const Common = @import("common.zig").Common;
const TypeItemKind = Common.TypeItemKind;
const TypeItemMutability = Common.TypeItemMutability;
const LookupMode = Common.LookupMode;
const LookupError = Common.LookupError;
const std = @import("std");
const testing = std.testing;
const expect = testing.expect;
const expectEqual = testing.expectEqual;
const expectError = testing.expectError;
const activeTag = std.meta.activeTag;
const eql = std.mem.eql;

// FindInType tests

/// Convenience wrapper for testing the
/// FindInType function over types.
pub fn test_findintype(
    // L = Look-up
    // E = Expected
    comptime target: type,
    comptime l_name: []const u8,
    comptime l_mode: LookupMode,
    comptime e_type: ?type,
    comptime e_kind: ?TypeItemKind,
    comptime e_default: ?*const anyopaque,
    comptime e_decl_const: ?bool,
    comptime e_outcome: enum { Success, Failure },
    comptime e_error: ?anyerror,
) !void {
    switch (e_outcome) {
        .Success => {
            const info = try Common.FindInType(target, l_name, l_mode);

            if (e_kind) |kind| {
                try expect(activeTag(info) == kind);
            } else return error.NullKind;

            if (e_type) |t| {
                try expect(info.GetType() == t);
            } else return error.NullType;

            try expect(eql(u8, info.GetName(), l_name));
            switch (info) {
                .StructField => {
                    try expect(info.GetDefaultValue() == e_default);
                },
                .Declaration => {
                    try expect(info.GetIsConstant() == e_decl_const.?);
                },
                else => {},
            }
        },
        .Failure => {
            const info = Common.FindInType(target, l_name, l_mode);
            if (e_error) |err| {
                try expectError(err, info);
            } else {
                return error.NullError;
            }
        },
    }
}

test "FindInType" {
    const test_struct = struct {
        a: i32,
        pub const b: i64 = 10;
        pub var c: i64 = 20;
    };

    try test_findintype(test_struct, "a", .Field, i32, .StructField, null, null, .Success, null);
    try test_findintype(test_struct, "a", .Any, i32, .StructField, null, null, .Success, null);
    try test_findintype(test_struct, "b", .Declaration, i64, .Declaration, null, true, .Success, null);
    try test_findintype(test_struct, "b", .Any, i64, .Declaration, null, true, .Success, null);
    try test_findintype(test_struct, "c", .Declaration, i64, .Declaration, null, false, .Success, null);
    try test_findintype(test_struct, "c", .Any, i64, .Declaration, null, false, .Success, null);

    try test_findintype(test_struct, "a", .Declaration, null, null, null, null, .Failure, LookupError.NotFound);
    try test_findintype(test_struct, "b", .Field, null, null, null, null, .Failure, LookupError.NotFound);

    const test_struct_empty = struct {};

    try test_findintype(test_struct_empty, "", .Field, null, null, null, null, .Failure, LookupError.TypeHasNoFields);
    try test_findintype(test_struct_empty, "", .Declaration, null, null, null, null, .Failure, LookupError.TypeHasNoDeclarations);
    try test_findintype(test_struct_empty, "", .Any, null, null, null, null, .Failure, LookupError.TypeHasNoFieldsOrDeclarations);

    const test_union = union {
        a: i32,
        pub const b: i64 = 10;
    };

    try test_findintype(test_union, "a", .Field, i32, .UnionField, null, null, .Success, null);
    try test_findintype(test_union, "a", .Any, i32, .UnionField, null, null, .Success, null);
    try test_findintype(test_union, "b", .Declaration, i64, .Declaration, null, true, .Success, null);
    try test_findintype(test_union, "b", .Any, i64, .Declaration, null, true, .Success, null);

    try test_findintype(test_union, "a", .Declaration, null, null, null, null, .Failure, LookupError.NotFound);
    try test_findintype(test_union, "b", .Field, null, null, null, null, .Failure, LookupError.NotFound);

    const test_union_empty = union {};

    try test_findintype(test_union_empty, "", .Field, null, null, null, null, .Failure, LookupError.TypeHasNoFields);
    try test_findintype(test_union_empty, "", .Declaration, null, null, null, null, .Failure, LookupError.TypeHasNoDeclarations);
    try test_findintype(test_union_empty, "", .Any, null, null, null, null, .Failure, LookupError.TypeHasNoFieldsOrDeclarations);

    const test_enum = enum {
        a,
        pub const b: i64 = 10;
    };

    // NOTE: Rethink the expected type on an enum. Maybe the enum should return the actual enum selector?
    //       Maybe a different function would be of use.
    try test_findintype(test_enum, "a", .Field, test_enum, .EnumField, null, null, .Success, null);
    try test_findintype(test_enum, "a", .Any, test_enum, .EnumField, null, null, .Success, null);
    try test_findintype(test_enum, "b", .Declaration, i64, .Declaration, null, true, .Success, null);
    try test_findintype(test_enum, "b", .Any, i64, .Declaration, null, true, .Success, null);

    try test_findintype(test_enum, "a", .Declaration, null, null, null, null, .Failure, LookupError.NotFound);
    try test_findintype(test_enum, "b", .Field, null, null, null, null, .Failure, LookupError.NotFound);

    const test_enum_empty = enum {};

    try test_findintype(test_enum_empty, "", .Field, null, null, null, null, .Failure, LookupError.TypeHasNoFields);
    try test_findintype(test_enum_empty, "", .Declaration, null, null, null, null, .Failure, LookupError.TypeHasNoDeclarations);
    try test_findintype(test_enum_empty, "", .Any, null, null, null, null, .Failure, LookupError.TypeHasNoFieldsOrDeclarations);

    //
    // For pointers, optionals, error unions, vectors and arrays
    // the test_struct type was used as the base.
    // Any other could have been chosen, but I have chosen this as it isolates
    // the checking for the base type from the pointer, optional, error union, vector
    // and array code-paths for checking (even though they eventually converge).
    //

    const test_pointer = *test_struct;

    try test_findintype(test_pointer, "a", .Field, i32, .StructField, null, null, .Success, null);
    try test_findintype(test_pointer, "a", .Any, i32, .StructField, null, null, .Success, null);
    try test_findintype(test_pointer, "b", .Declaration, i64, .Declaration, null, true, .Success, null);
    try test_findintype(test_pointer, "b", .Any, i64, .Declaration, null, true, .Success, null);

    try test_findintype(test_pointer, "a", .Declaration, null, null, null, null, .Failure, LookupError.NotFound);
    try test_findintype(test_pointer, "b", .Field, null, null, null, null, .Failure, LookupError.NotFound);

    const test_optional = ?test_struct;

    try test_findintype(test_optional, "a", .Field, i32, .StructField, null, null, .Success, null);
    try test_findintype(test_optional, "a", .Any, i32, .StructField, null, null, .Success, null);
    try test_findintype(test_optional, "b", .Declaration, i64, .Declaration, null, true, .Success, null);
    try test_findintype(test_optional, "b", .Any, i64, .Declaration, null, true, .Success, null);

    try test_findintype(test_optional, "a", .Declaration, null, null, null, null, .Failure, LookupError.NotFound);
    try test_findintype(test_optional, "b", .Field, null, null, null, null, .Failure, LookupError.NotFound);

    const test_error_union = anyerror!test_struct;

    try test_findintype(test_error_union, "a", .Field, i32, .StructField, null, null, .Success, null);
    try test_findintype(test_error_union, "a", .Any, i32, .StructField, null, null, .Success, null);
    try test_findintype(test_error_union, "b", .Declaration, i64, .Declaration, null, true, .Success, null);
    try test_findintype(test_error_union, "b", .Any, i64, .Declaration, null, true, .Success, null);

    try test_findintype(test_error_union, "a", .Declaration, null, null, null, null, .Failure, LookupError.NotFound);
    try test_findintype(test_error_union, "b", .Field, null, null, null, null, .Failure, LookupError.NotFound);

    const test_vector = @Vector(4, *test_struct);

    try test_findintype(test_vector, "a", .Field, i32, .StructField, null, null, .Success, null);
    try test_findintype(test_vector, "a", .Any, i32, .StructField, null, null, .Success, null);
    try test_findintype(test_vector, "b", .Declaration, i64, .Declaration, null, true, .Success, null);
    try test_findintype(test_vector, "b", .Any, i64, .Declaration, null, true, .Success, null);

    try test_findintype(test_vector, "a", .Declaration, null, null, null, null, .Failure, LookupError.NotFound);
    try test_findintype(test_vector, "b", .Field, null, null, null, null, .Failure, LookupError.NotFound);

    const test_array = [4]test_struct;

    try test_findintype(test_array, "a", .Field, i32, .StructField, null, null, .Success, null);
    try test_findintype(test_array, "a", .Any, i32, .StructField, null, null, .Success, null);
    try test_findintype(test_array, "b", .Declaration, i64, .Declaration, null, true, .Success, null);
    try test_findintype(test_array, "b", .Any, i64, .Declaration, null, true, .Success, null);

    try test_findintype(test_array, "a", .Declaration, null, null, null, null, .Failure, LookupError.NotFound);
    try test_findintype(test_array, "b", .Field, null, null, null, null, .Failure, LookupError.NotFound);
}
