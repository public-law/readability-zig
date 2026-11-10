const std = @import("std");

const named_entities = std.StaticStringMap(u21).initComptime(.{
    .{ "amp", '&' },
    .{ "AMP", '&' },
    .{ "lt", '<' },
    .{ "LT", '<' },
    .{ "gt", '>' },
    .{ "GT", '>' },
    .{ "quot", '"' },
    .{ "QUOT", '"' },
    .{ "apos", '\'' },
    .{ "nbsp", 0xA0 },
    .{ "NBSP", 0xA0 },
});

pub fn text(allocator: std.mem.Allocator, html: []const u8) std.mem.Allocator.Error![]u8 {
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);
    try out.ensureTotalCapacity(allocator, html.len);

    var i: usize = 0;
    while (i < html.len) {
        if (std.mem.startsWith(u8, html[i..], "<!--")) {
            i += 4;
            if (std.mem.indexOf(u8, html[i..], "-->")) |rel| {
                i += rel + 3;
            } else {
                i = html.len;
            }
        } else if (html[i] == '<') {
            i = skip_tag(html, i);
        } else if (html[i] == '&') {
            i = try append_entity(allocator, &out, html, i);
        } else {
            try out.append(allocator, html[i]);
            i += 1;
        }
    }

    return out.toOwnedSlice(allocator);
}

fn skip_tag(html: []const u8, start: usize) usize {
    var quote: ?u8 = null;
    var i = start + 1;
    while (i < html.len) : (i += 1) {
        const c = html[i];
        if (quote) |q| {
            if (c == q) quote = null;
        } else if (c == '"' or c == '\'') {
            quote = c;
        } else if (c == '>') {
            return i + 1;
        }
    }
    return html.len;
}

fn append_entity(allocator: std.mem.Allocator, out: *std.ArrayList(u8), html: []const u8, start: usize) std.mem.Allocator.Error!usize {
    const rest = html[start + 1 ..];
    if (rest.len == 0) {
        try out.append(allocator, '&');
        return start + 1;
    }

    if (rest[0] == '#') {
        const hex = rest.len > 1 and (rest[1] == 'x' or rest[1] == 'X');
        const digits = if (hex) rest[2..] else rest[1..];
        var value: u32 = 0;
        var n: usize = 0;
        while (n < digits.len) : (n += 1) {
            const d = digits[n];
            if (d == ';') break;
            const digit: u32 = if (hex)
                std.fmt.charToDigit(d, 16) catch break
            else
                std.fmt.charToDigit(d, 10) catch break;
            value = value *% (if (hex) @as(u32, 16) else 10) + digit;
        }
        if (n > 0 and n < digits.len and digits[n] == ';') {
            if (value <= 0x10FFFF) {
                try append_codepoint(allocator, out, @intCast(value));
                const prefix: usize = if (hex) 3 else 2;
                return start + prefix + n + 1;
            }
        }
        try out.append(allocator, '&');
        return start + 1;
    }

    var n: usize = 0;
    while (n < rest.len) : (n += 1) {
        const c = rest[n];
        if (c == ';') break;
        const ok = (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or (c >= '0' and c <= '9');
        if (!ok) break;
    }
    if (n > 0 and n < rest.len and rest[n] == ';') {
        if (named_entities.get(rest[0..n])) |cp| {
            try append_codepoint(allocator, out, cp);
            return start + n + 2;
        }
    }

    try out.append(allocator, '&');
    return start + 1;
}

fn append_codepoint(allocator: std.mem.Allocator, out: *std.ArrayList(u8), cp: u21) std.mem.Allocator.Error!void {
    var buf: [4]u8 = undefined;
    const len = std.unicode.utf8Encode(cp, &buf) catch {
        const replacement = [_]u8{ 0xEF, 0xBF, 0xBD };
        try out.appendSlice(allocator, &replacement);
        return;
    };
    try out.appendSlice(allocator, buf[0..len]);
}
