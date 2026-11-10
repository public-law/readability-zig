const std = @import("std");

const arbitrary_max = 64.0;
const arbitrary_min = 10.0;

const levels = [_]struct { floor: f64, level: []const u8 }{
    .{ .floor = 58, .level = "1" },
    .{ .floor = 54, .level = "2" },
    .{ .floor = 50, .level = "3" },
    .{ .floor = 45, .level = "4" },
    .{ .floor = 40, .level = "5-6" },
    .{ .floor = 34, .level = "7-8" },
    .{ .floor = 28, .level = "9-10" },
    .{ .floor = 22, .level = "11-12" },
    .{ .floor = 16, .level = "13-15" },
};

pub fn compute_reading_level(pct_unfamiliar_words: f64, avg_sentence_length: f64) []const u8 {
    return reading_level_from_cloze(compute_cloze_score(pct_unfamiliar_words, avg_sentence_length));
}

pub fn reading_level_from_cloze(cloze_score: f64) []const u8 {
    const bounded = std.math.clamp(cloze_score, arbitrary_min, arbitrary_max);
    const key = @ceil(bounded);
    for (levels) |entry| {
        if (key >= entry.floor) return entry.level;
    }
    return "16+";
}

pub fn compute_cloze_score(pct_unfamiliar_words: f64, avg_sentence_length: f64) f64 {
    return round_to_2(64 - (95 * pct_unfamiliar_words) - (0.69 * avg_sentence_length));
}

pub fn round_to_2(x: f64) f64 {
    var buf: [64]u8 = undefined;
    const formatted = std.fmt.bufPrint(&buf, "{d:.2}", .{x}) catch {
        return python_round_to_2(x);
    };
    return std.fmt.parseFloat(f64, formatted) catch python_round_to_2(x);
}

fn python_round_to_2(x: f64) f64 {
    if (!std.math.isFinite(x)) return x;
    const sign: f64 = if (x < 0) -1 else 1;
    const scaled = @abs(x) * 100.0;
    var whole = @floor(scaled);
    const frac = scaled - whole;
    if (frac > 0.5 or (frac == 0.5 and @mod(whole, 2) != 0)) {
        whole += 1;
    }
    return sign * whole / 100.0;
}
