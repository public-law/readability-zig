const std = @import("std");
const html = @import("html.zig");

const easy_words = blk: {
    @setEvalBranchQuota(100_000);
    const src = @embedFile("easy_words.txt");
    const n = count_lines(src);
    var items: [n][]const u8 = undefined;
    var i: usize = 0;
    var start: usize = 0;
    for (src, 0..) |c, idx| {
        if (c == '\n') {
            if (idx > start) {
                items[i] = src[start..idx];
                i += 1;
            }
            start = idx + 1;
        }
    }
    if (start < src.len) {
        items[i] = src[start..];
    }
    break :blk items;
};

pub fn pct_unfamiliar_words(allocator: std.mem.Allocator, text: []const u8) error{ DivisionByZero, OutOfMemory }!f64 {
    const counts = try count_words(allocator, text);
    if (counts.words == 0) return error.DivisionByZero;
    return @as(f64, @floatFromInt(counts.unfamiliar)) / @as(f64, @floatFromInt(counts.words));
}

pub fn avg_sentence_length(allocator: std.mem.Allocator, text: []const u8) error{ DivisionByZero, OutOfMemory }!f64 {
    const sentences = count_sentences(text);
    if (sentences == 0) return error.DivisionByZero;
    const counts = try count_words(allocator, text);
    return @as(f64, @floatFromInt(counts.words)) / @as(f64, @floatFromInt(sentences));
}

const WordCounts = struct { words: usize, unfamiliar: usize };

fn count_words(allocator: std.mem.Allocator, text: []const u8) std.mem.Allocator.Error!WordCounts {
    const visible = try html.text(allocator, text);
    defer allocator.free(visible);

    var scratch: std.ArrayList(u8) = .empty;
    defer scratch.deinit(allocator);

    var words: usize = 0;
    var unfamiliar: usize = 0;
    var i: usize = 0;
    while (i < visible.len) {
        while (i < visible.len and is_space(codepoint_at(visible, i))) {
            i = next_index(visible, i);
        }
        if (i >= visible.len) break;
        const start = i;
        while (i < visible.len and !is_space(codepoint_at(visible, i))) {
            i = next_index(visible, i);
        }
        words += 1;
        if (try is_unfamiliar(allocator, &scratch, visible[start..i])) {
            unfamiliar += 1;
        }
    }
    return .{ .words = words, .unfamiliar = unfamiliar };
}

fn is_unfamiliar(allocator: std.mem.Allocator, scratch: *std.ArrayList(u8), word: []const u8) std.mem.Allocator.Error!bool {
    scratch.clearRetainingCapacity();
    try append_lowered(allocator, scratch, word);

    var start: usize = 0;
    var end: usize = scratch.items.len;
    while (start < end and is_strip_punct(scratch.items[start])) start += 1;
    while (end > start and is_strip_punct(scratch.items[end - 1])) end -= 1;

    const stripped = scratch.items[start..end];
    const prepared = remove_possessives(stripped);
    if (is_number(prepared)) return false;
    return !is_easy_word(prepared);
}

fn append_lowered(allocator: std.mem.Allocator, scratch: *std.ArrayList(u8), word: []const u8) std.mem.Allocator.Error!void {
    var i: usize = 0;
    while (i < word.len) {
        const c = word[i];
        if (c < 128) {
            try scratch.append(allocator, std.ascii.toLower(c));
            i += 1;
        } else {
            const len = std.unicode.utf8ByteSequenceLength(c) catch 1;
            const next = @min(i + len, word.len);
            try scratch.appendSlice(allocator, word[i..next]);
            i = next;
        }
    }
}

fn remove_possessives(word: []u8) []u8 {
    const without_s = remove_all(word, "'s");
    return remove_all(without_s, "s'");
}

fn remove_all(word: []u8, needle: []const u8) []u8 {
    var r: usize = 0;
    var w: usize = 0;
    while (r < word.len) {
        if (r + needle.len <= word.len and std.mem.eql(u8, word[r .. r + needle.len], needle)) {
            r += needle.len;
        } else {
            word[w] = word[r];
            w += 1;
            r += 1;
        }
    }
    return word[0..w];
}

fn is_number(word: []const u8) bool {
    if (word.len == 0) return false;
    for (word) |c| {
        if (!std.ascii.isDigit(c)) return false;
    }
    return true;
}

fn is_easy_word(word: []const u8) bool {
    var lo: usize = 0;
    var hi: usize = easy_words.len;
    while (lo < hi) {
        const mid = lo + (hi - lo) / 2;
        switch (std.mem.order(u8, easy_words[mid], word)) {
            .eq => return true,
            .gt => hi = mid,
            .lt => lo = mid + 1,
        }
    }
    return false;
}

fn count_sentences(text: []const u8) usize {
    const start = skip_space(text, 0);
    const end = end_without_trailing_space(text, start);
    if (start >= end) return 0;

    var count: usize = 0;
    var i = start;
    while (i < end) {
        if (is_word_boundary(text, start, end, i) and i < end and !is_terminator(codepoint_at(text, i))) {
            while (i < end and !is_terminator(codepoint_at(text, i))) {
                i = next_index(text, i);
            }
            while (i < end and is_terminator(codepoint_at(text, i))) {
                i = next_index(text, i);
            }
            count += 1;
        } else {
            i = next_index(text, i);
        }
    }
    return count;
}

fn is_word_boundary(text: []const u8, start: usize, end: usize, i: usize) bool {
    const left_word = if (i > start) is_word_char(codepoint_before(text, i)) else false;
    const right_word = if (i < end) is_word_char(codepoint_at(text, i)) else false;
    return left_word != right_word;
}

fn skip_space(text: []const u8, start: usize) usize {
    var i = start;
    while (i < text.len and is_space(codepoint_at(text, i))) {
        i = next_index(text, i);
    }
    return i;
}

fn end_without_trailing_space(text: []const u8, start: usize) usize {
    var i = text.len;
    while (i > start) {
        const prev = prev_index(text, i);
        if (!is_space(codepoint_at(text, prev))) return i;
        i = prev;
    }
    return start;
}

fn is_strip_punct(c: u8) bool {
    return c == '.' or c == '(' or c == ')' or c == ',' or c == '"';
}

fn is_terminator(cp: u21) bool {
    return cp == '.' or cp == '!' or cp == '?';
}

fn is_word_char(cp: u21) bool {
    if (cp == '_') return true;
    if (cp < 128) return std.ascii.isAlphanumeric(@intCast(cp));
    return is_letterish(cp);
}

fn is_letterish(cp: u21) bool {
    return (cp >= 0xC0 and cp <= 0x24F and cp != 0xD7 and cp != 0xF7) or
        (cp >= 0x370 and cp <= 0x1FFF) or
        (cp >= 0x2C00 and cp <= 0xD7FF) or
        (cp >= 0xF900 and cp <= 0xFFDC);
}

fn is_space(cp: u21) bool {
    return switch (cp) {
        ' ', '\t', '\n', '\r', 0x0B, 0x0C, 0x1C, 0x1D, 0x1E, 0x1F, 0x85, 0xA0 => true,
        0x1680, 0x2028, 0x2029, 0x202F, 0x205F, 0x3000 => true,
        else => cp >= 0x2000 and cp <= 0x200A,
    };
}

fn count_lines(src: []const u8) usize {
    var n: usize = 0;
    var start: usize = 0;
    for (src, 0..) |c, i| {
        if (c == '\n') {
            if (i > start) n += 1;
            start = i + 1;
        }
    }
    if (start < src.len) n += 1;
    return n;
}

fn codepoint_at(text: []const u8, i: usize) u21 {
    const len = std.unicode.utf8ByteSequenceLength(text[i]) catch return text[i];
    const end = i + len;
    if (end > text.len) return text[i];
    return std.unicode.utf8Decode(text[i..end]) catch text[i];
}

fn codepoint_before(text: []const u8, i: usize) u21 {
    return codepoint_at(text, prev_index(text, i));
}

fn next_index(text: []const u8, i: usize) usize {
    if (i >= text.len) return text.len;
    const len = std.unicode.utf8ByteSequenceLength(text[i]) catch 1;
    return @min(i + len, text.len);
}

fn prev_index(text: []const u8, i: usize) usize {
    var j = i;
    while (j > 0) {
        j -= 1;
        if (text[j] & 0xC0 != 0x80) return j;
    }
    return 0;
}
