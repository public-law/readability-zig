const std = @import("std");
const utils = @import("readability").utils;

test "all familiar words" {
    try std.testing.expectEqual(@as(f64, 0.0), try utils.pct_unfamiliar_words(std.testing.allocator, "Dog cat play house."));
}

test "repeated uses" {
    try std.testing.expectEqual(@as(f64, 0.5), try utils.pct_unfamiliar_words(std.testing.allocator, "Dog respondent dog respondent dog respondent."));
}

test "mixed uses" {
    try std.testing.expectEqual(@as(f64, 0.5), try utils.pct_unfamiliar_words(std.testing.allocator, "Dog raconteur dog respondent dog respondent."));
}

test "all unfamiliar words" {
    try std.testing.expectEqual(@as(f64, 1.0), try utils.pct_unfamiliar_words(std.testing.allocator, "Deponent deponent deponent."));
}

test "possessives" {
    try std.testing.expectEqual(@as(f64, 0.0), try utils.pct_unfamiliar_words(std.testing.allocator, "Dog's dog's dog's."));
}

test "plural possessives" {
    try std.testing.expectEqual(@as(f64, 0.0), try utils.pct_unfamiliar_words(std.testing.allocator, "Dogs' dog's dogs'."));
}

test "embedded html" {
    try std.testing.expectEqual(@as(f64, 0.0), try utils.pct_unfamiliar_words(std.testing.allocator, "Dog <em>dog</em> dog."));
}

test "embedded year" {
    try std.testing.expectEqual(@as(f64, 0.0), try utils.pct_unfamiliar_words(std.testing.allocator, "A dog born in 2020."));
}

test "embedded ages" {
    try std.testing.expectEqual(@as(f64, 0.0), try utils.pct_unfamiliar_words(std.testing.allocator, "A boy or girl aged 14, 15 or 16."));
}
