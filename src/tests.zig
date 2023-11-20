/// Metaplasia Tests
/// ©2023 Cristian Vasilache (NNCV / Nylvon)
///
/// Provides an exhaustive test suite for the Metaplasia library.
/// Each test name is formatted as follows:
/// "[FeatureName] [Scenario]"
pub const MetaplasiaTests = @This();
const Metaplasia = @import("metaplasia.zig");
const Common = Metaplasia.Common;
const LookupError = Common.LookupError;
const std = @import("std");
const testing = std.testing;
const expect = testing.expect;
const expectEqual = testing.expectEqual;
const expectError = testing.expectError;

// FindInType tests

test "FindInType Struct" {
    const sample_type = struct {
        a: i32,
        pub const b: i64 = 10;
    };

    // Try to find the field
    // First two should not error, the third should error
    const field_info = try Common.FindInType(sample_type, "a", .Field);
    try expect(field_info.GetType() == i32);
    const field_info_any = try Common.FindInType(sample_type, "a", .Any);
    try expect(field_info_any.GetType() == i32);
    const field_error = Common.FindInType(sample_type, "a", .Declaration);
    try expectError(LookupError.NotFound, field_error);

    // Try to find the declaration
    // // First two should not error, the third should error
    // const decl_info = try Common.FindInType(sample_type, "b", .Declaration);
    // try expect(decl_info == i64);
    // const decl_info_any = try Common.FindInType(sample_type, "b", .Any);
    // try expect(decl_info_any == i64);
    // const decl_error = Common.FindInType(sample_type, "b", .Field);
    // try expectError(LookupError.NotFound, decl_error);
}

// test "FindInType Struct Empty" {
//     const sample_type = struct {};

//     const field_error = Common.FindInType(sample_type, "a", .Field);
//     try expectError(LookupError.TypeHasNoFields, field_error);
//     const decl_error = Common.FindInType(sample_type, "a", .Declaration);
//     try expectError(LookupError.TypeHasNoDeclarations, decl_error);
//     const any_error = Common.FindInType(sample_type, "a", .Any);
//     try expectError(LookupError.TypeHasNoFieldsOrDeclarations, any_error);
// }

// test "FindInType Union" {
//     const sample_type = union {
//         a: i32,
//         pub const b: i64 = 10;
//     };

//     // Try to find the field
//     // First two should not error, the third should error
//     const field_type = try Common.FindInType(sample_type, "a", .Field);
//     try expect(field_type == i32);
//     const field_type_any = try Common.FindInType(sample_type, "a", .Any);
//     try expect(field_type_any == i32);
//     const field_error = Common.FindInType(sample_type, "a", .Declaration);
//     try expectError(LookupError.NotFound, field_error);

//     // Try to find the declaration
//     // First two should not error, the third should error
//     const decl_type = try Common.FindInType(sample_type, "b", .Declaration);
//     try expect(decl_type == i64);
//     const decl_type_any = try Common.FindInType(sample_type, "b", .Any);
//     try expect(decl_type_any == i64);
//     const decl_error = Common.FindInType(sample_type, "b", .Field);
//     try expectError(LookupError.NotFound, decl_error);
// }

// test "FindInType Union Empty" {
//     const sample_type = union {};

//     const field_error = Common.FindInType(sample_type, "a", .Field);
//     try expectError(LookupError.TypeHasNoFields, field_error);
//     const decl_error = Common.FindInType(sample_type, "a", .Declaration);
//     try expectError(LookupError.TypeHasNoDeclarations, decl_error);
//     const any_error = Common.FindInType(sample_type, "a", .Any);
//     try expectError(LookupError.TypeHasNoFieldsOrDeclarations, any_error);
// }

// test "FindInType Enum" {
//     const sample_type = enum {
//         a,
//         pub const b: i64 = 10;
//     };

//     // Try to find the field
//     // First two should not error, the third should error
//     const field_type = try Common.FindInType(sample_type, "a", .Field);
//     try expect(field_type == sample_type.a);
//     const field_type_any = try Common.FindInType(sample_type, "a", .Any);
//     try expect(field_type_any.field == sample_type.a);
//     const field_error = Common.FindInType(sample_type, "a", .Declaration);
//     try expectError(LookupError.NotFound, field_error);

//     // Try to find the declaration
//     // First two should not error, the third should error
//     const decl_type = try Common.FindInType(sample_type, "b", .Declaration);
//     try expect(decl_type == i64);
//     const decl_type_any = try Common.FindInType(sample_type, "b", .Any);
//     try expect(decl_type_any.decl == i64);
//     const decl_error = Common.FindInType(sample_type, "b", .Field);
//     try expectError(LookupError.NotFound, decl_error);
// }

// test "FindInType Enum Empty" {
//     const sample_type_a = enum { a };

//     // Enums cannot be empty (for now; due to an error in std.fmt:527:46 (@tagName of empty enum is impossible))
//     const decl_error = Common.FindInType(sample_type_a, "a", .Declaration);
//     try expectError(LookupError.TypeHasNoDeclarations, decl_error);
// }

// test "FindInType Pointer" {
//     const sample_type = struct {
//         a: i32,
//         pub const b: i64 = 10;
//     };

//     const target_type = *sample_type;

//     // Try to find the field
//     // First two should not error, the third should error
//     const field_type = try Common.FindInType(target_type, "a", .Field);
//     try expect(field_type == i32);
//     const field_type_any = try Common.FindInType(target_type, "a", .Any);
//     try expect(field_type_any == i32);
//     const field_error = Common.FindInType(target_type, "a", .Declaration);
//     try expectError(LookupError.NotFound, field_error);

//     // Try to find the declaration
//     // First two should not error, the third should error
//     const decl_type = try Common.FindInType(target_type, "b", .Declaration);
//     try expect(decl_type == i64);
//     const decl_type_any = try Common.FindInType(target_type, "b", .Any);
//     try expect(decl_type_any == i64);
//     const decl_error = Common.FindInType(target_type, "b", .Field);
//     try expectError(LookupError.NotFound, decl_error);
// }

// test "FindInType Optional" {
//     const sample_type = struct {
//         a: i32,
//         pub const b: i64 = 10;
//     };

//     const target_type = ?sample_type;

//     // Try to find the field
//     // First two should not error, the third should error
//     const field_type = try Common.FindInType(target_type, "a", .Field);
//     try expect(field_type == i32);
//     const field_type_any = try Common.FindInType(target_type, "a", .Any);
//     try expect(field_type_any == i32);
//     const field_error = Common.FindInType(target_type, "a", .Declaration);
//     try expectError(LookupError.NotFound, field_error);

//     // Try to find the declaration
//     // First two should not error, the third should error
//     const decl_type = try Common.FindInType(target_type, "b", .Declaration);
//     try expect(decl_type == i64);
//     const decl_type_any = try Common.FindInType(target_type, "b", .Any);
//     try expect(decl_type_any == i64);
//     const decl_error = Common.FindInType(target_type, "b", .Field);
//     try expectError(LookupError.NotFound, decl_error);
// }

// test "FindInType Error Union" {
//     const sample_type = struct {
//         a: i32,
//         pub const b: i64 = 10;
//     };

//     const target_type = anyerror!sample_type;

//     // Try to find the field
//     // First two should not error, the third should error
//     const field_type = try Common.FindInType(target_type, "a", .Field);
//     try expect(field_type == i32);
//     const field_type_any = try Common.FindInType(target_type, "a", .Any);
//     try expect(field_type_any == i32);
//     const field_error = Common.FindInType(target_type, "a", .Declaration);
//     try expectError(LookupError.NotFound, field_error);

//     // Try to find the declaration
//     // First two should not error, the third should error
//     const decl_type = try Common.FindInType(target_type, "b", .Declaration);
//     try expect(decl_type == i64);
//     const decl_type_any = try Common.FindInType(target_type, "b", .Any);
//     try expect(decl_type_any == i64);
//     const decl_error = Common.FindInType(target_type, "b", .Field);
//     try expectError(LookupError.NotFound, decl_error);
// }

// test "FindInType Vector" {
//     const sample_type = struct {
//         a: i32,
//         pub const b: i64 = 10;
//     };

//     const target_type = @Vector(4, *sample_type);

//     // Try to find the field
//     // First two should not error, the third should error
//     const field_type = try Common.FindInType(target_type, "a", .Field);
//     try expect(field_type == i32);
//     const field_type_any = try Common.FindInType(target_type, "a", .Any);
//     try expect(field_type_any == i32);
//     const field_error = Common.FindInType(target_type, "a", .Declaration);
//     try expectError(LookupError.NotFound, field_error);

//     // Try to find the declaration
//     // First two should not error, the third should error
//     const decl_type = try Common.FindInType(target_type, "b", .Declaration);
//     try expect(decl_type == i64);
//     const decl_type_any = try Common.FindInType(target_type, "b", .Any);
//     try expect(decl_type_any == i64);
//     const decl_error = Common.FindInType(target_type, "b", .Field);
//     try expectError(LookupError.NotFound, decl_error);
// }

// test "FindInType Array" {
//     const sample_type = struct {
//         a: i32,
//         pub const b: i64 = 10;
//     };

//     const target_type = [4]sample_type;

//     // Try to find the field
//     // First two should not error, the third should error
//     const field_type = try Common.FindInType(target_type, "a", .Field);
//     try expect(field_type == i32);
//     const field_type_any = try Common.FindInType(target_type, "a", .Any);
//     try expect(field_type_any == i32);
//     const field_error = Common.FindInType(target_type, "a", .Declaration);
//     try expectError(LookupError.NotFound, field_error);

//     // Try to find the declaration
//     // First two should not error, the third should error
//     const decl_type = try Common.FindInType(target_type, "b", .Declaration);
//     try expect(decl_type == i64);
//     const decl_type_any = try Common.FindInType(target_type, "b", .Any);
//     try expect(decl_type_any == i64);
//     const decl_error = Common.FindInType(target_type, "b", .Field);
//     try expectError(LookupError.NotFound, decl_error);
// }
