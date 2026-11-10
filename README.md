# readability-zig

A Zig port of [new-dale-chall-readability](https://github.com/public-law/readability).
It has the same functions as the Python library.

Requires [Zig 0.17.1](https://ziglang.org/download/).

## Usage

```zig
const readability = @import("readability");

const text = "Latin for \"friend of the court.\" It is advice formally offered " ++
    "to the court in a brief filed by an entity interested in, but not " ++
    "a party to, the case.";

const level = try readability.reading_level(allocator, text); // 7-8
const score = try readability.cloze_score(allocator, text); // 36.91
```

The formulas and measurements are in the same modules as in Python:

```zig
const formulas = readability.formulas;
const utils = readability.utils;

_ = formulas.compute_cloze_score(0.2, 10.0); // 38.1
_ = formulas.compute_reading_level(0.2, 10.0); // 7-8
_ = formulas.reading_level_from_cloze(44.0); // 5-6

_ = try utils.pct_unfamiliar_words(allocator, "Dog respondent dog respondent."); // 0.5
_ = try utils.avg_sentence_length(allocator, "The dog ran. It was late."); // 3.0
```

Text functions take an allocator because they may copy the input while
stripping HTML. Text with no words or no sentences returns
`error.DivisionByZero`, where Python raises `ZeroDivisionError`.

HTML handling removes tags and comments and decodes numeric entities plus
a few named ones such as `&amp;` and `&nbsp;`. It is not a full port of
html.parser and BeautifulSoup. Scores match on the Python library's test
inputs; unusual markup can produce different words.

## Tests

```
zig build test
```

This runs the tests from the Python library.

## License

MIT
