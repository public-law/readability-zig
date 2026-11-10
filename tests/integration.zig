const std = @import("std");
const readability = @import("readability");

const highlights_for_children = @embedFile("fixtures/highlights_for_children.txt");
const psychology_today = @embedFile("fixtures/psychology_today.txt");
const harvard_ed_rev = @embedFile("fixtures/harvard_ed_rev.txt");

test "highlights for children cloze score" {
    try std.testing.expectApproxEqAbs(
        @as(f64, 53.0),
        try readability.cloze_score(std.testing.allocator, highlights_for_children),
        0.01,
    );
}

test "highlights for children reading level" {
    try std.testing.expectEqualStrings(
        "3",
        try readability.reading_level(std.testing.allocator, highlights_for_children),
    );
}

test "psychology today cloze score" {
    try std.testing.expectApproxEqAbs(
        @as(f64, 17.0),
        try readability.cloze_score(std.testing.allocator, psychology_today),
        0.01,
    );
}

test "psychology today reading level" {
    try std.testing.expectEqualStrings(
        "13-15",
        try readability.reading_level(std.testing.allocator, psychology_today),
    );
}

test "harvard ed rev cloze score" {
    try std.testing.expectApproxEqAbs(
        @as(f64, -6.0),
        try readability.cloze_score(std.testing.allocator, harvard_ed_rev),
        0.01,
    );
}

test "harvard ed rev reading level" {
    try std.testing.expectEqualStrings(
        "16+",
        try readability.reading_level(std.testing.allocator, harvard_ed_rev),
    );
}
