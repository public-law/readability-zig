const std = @import("std");
const formulas = @import("readability").formulas;

test "cloze score of simple inputs" {
    try std.testing.expectEqual(@as(f64, 38.1), formulas.compute_cloze_score(0.2, 10.0));
}

test "cloze score of book sample" {
    try std.testing.expectEqual(@as(f64, 50.99), formulas.compute_cloze_score(0.11, 100.0 / 27.0));
}

test "reading level inside a band" {
    try std.testing.expectEqualStrings("5-6", formulas.reading_level_from_cloze(39.01));
}

test "reading level on a band edge" {
    try std.testing.expectEqualStrings("5-6", formulas.reading_level_from_cloze(44.0));
}

test "reading level of a very difficult score" {
    try std.testing.expectEqualStrings("16+", formulas.reading_level_from_cloze(11.2));
}

test "reading level of the highest score" {
    try std.testing.expectEqualStrings("1", formulas.reading_level_from_cloze(64.0));
}

test "reading level of the lowest band" {
    try std.testing.expectEqualStrings("16+", formulas.reading_level_from_cloze(15));
}

test "compute reading level of simple inputs" {
    try std.testing.expectEqualStrings("7-8", formulas.compute_reading_level(0.2, 10.0));
}

test "compute reading level of book sample" {
    try std.testing.expectEqualStrings("3", formulas.compute_reading_level(0.11, 100.0 / 27.0));
}
