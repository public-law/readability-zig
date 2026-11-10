const std = @import("std");

pub const formulas = @import("formulas.zig");
pub const utils = @import("utils.zig");

pub const compute_cloze_score = formulas.compute_cloze_score;
pub const compute_reading_level = formulas.compute_reading_level;
pub const reading_level_from_cloze = formulas.reading_level_from_cloze;
pub const avg_sentence_length = utils.avg_sentence_length;
pub const pct_unfamiliar_words = utils.pct_unfamiliar_words;

const compensation_ultra_low: f64 = 1.305;
const compensation_lower: f64 = 1.1725;
const compensation_higher: f64 = 1.2315;

pub fn cloze_score(allocator: std.mem.Allocator, text: []const u8) error{ DivisionByZero, OutOfMemory }!f64 {
    const raw = compute_cloze_score(
        try pct_unfamiliar_words(allocator, text),
        try avg_sentence_length(allocator, text),
    );
    const compensation = if (raw >= 40)
        compensation_higher
    else if (raw > 0)
        compensation_lower
    else
        compensation_ultra_low;
    return formulas.round_to_2(raw * compensation);
}

pub fn reading_level(allocator: std.mem.Allocator, text: []const u8) error{ DivisionByZero, OutOfMemory }![]const u8 {
    return reading_level_from_cloze(try cloze_score(allocator, text));
}
