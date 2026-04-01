import AppKit
import SwiftUI

// MARK: - Public API

enum SyntaxHighlighter {

    /// NSAttributedString for NSTextView — NSFont (SF Mono) + NSColor, no scope issues.
    static func highlightNS(_ code: String, dark: Bool, fontSize: CGFloat = 12) -> NSAttributedString {
        let theme: Theme = dark ? .dark : .light
        let font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        let ns = NSMutableAttributedString(
            string: code,
            attributes: [.font: font, .foregroundColor: theme.text]
        )
        guard code.count < 15_000 else { return ns }
        var covered = IndexSet()
        for rule in compiled {
            let fullRange = NSRange(code.startIndex..., in: code)
            for match in rule.regex.matches(in: code, options: [], range: fullRange) {
                let r = match.range
                guard r.length > 0 else { continue }
                let lo = r.location, hi = lo + r.length
                guard !covered.intersects(integersIn: lo..<hi) else { continue }
                ns.addAttribute(.foregroundColor, value: theme[keyPath: rule.colorKey], range: r)
                covered.insert(integersIn: lo..<hi)
            }
        }
        return ns
    }

    /// SwiftUI AttributedString for Text views (list preview).
    /// Regexes are compiled once (static let) — O(1) subsequent calls.
    static func highlight(_ code: String, dark: Bool, fontSize: CGFloat = 12) -> AttributedString {
        let theme: Theme = dark ? .dark : .light
        var result = AttributedString(code)
        result.font = .system(size: fontSize, design: .monospaced)
        result.foregroundColor = Color(theme.text)

        // Skip highlighting for huge pastes (rare, but safe)
        guard code.count < 15_000 else { return result }

        var covered = IndexSet()
        for rule in compiled {
            let fullRange = NSRange(code.startIndex..., in: code)
            for match in rule.regex.matches(in: code, options: [], range: fullRange) {
                let r = match.range
                guard r.length > 0 else { continue }
                let lo = r.location, hi = lo + r.length
                guard !covered.intersects(integersIn: lo..<hi) else { continue }
                guard let strRange = Range(r, in: code),
                      let lower = index(strRange.lowerBound, in: code, of: result),
                      let upper = index(strRange.upperBound, in: code, of: result)
                else { continue }
                result[lower..<upper].foregroundColor = Color(theme[keyPath: rule.colorKey])
                covered.insert(integersIn: lo..<hi)
            }
        }
        return result
    }

    // MARK: - Index conversion

    private static func index(
        _ si: String.Index, in code: String, of attr: AttributedString
    ) -> AttributedString.Index? {
        let offset = code.distance(from: code.startIndex, to: si)
        let chars = attr.characters
        guard offset >= 0, offset <= chars.count else { return nil }
        return chars.index(chars.startIndex, offsetBy: offset)
    }

    // MARK: - Compiled rules (lazy, created once)

    private struct Rule {
        let regex: NSRegularExpression
        let colorKey: KeyPath<Theme, NSColor>
    }

    private static let compiled: [Rule] = rawRules.compactMap { raw in
        guard let rx = try? NSRegularExpression(pattern: raw.0, options: raw.1) else { return nil }
        return Rule(regex: rx, colorKey: raw.2)
    }

    // (pattern, options, colorKeyPath) — ordered by priority (first match wins)
    private static let rawRules: [(String, NSRegularExpression.Options, KeyPath<Theme, NSColor>)] = [
        (#"//[^\n]*"#,                          [],                          \.comment),
        (#"/\*[\s\S]*?\*/"#,                    [.dotMatchesLineSeparators], \.comment),
        (#"#[^\n]*"#,                           [],                          \.comment),   // Python/shell
        (#"\"\"\"[\s\S]*?\"\"\""#,              [.dotMatchesLineSeparators], \.string),
        (#""(?:[^"\\]|\\.)*""#,                 [],                          \.string),
        (#"'(?:[^'\\]|\\.)*'"#,                 [],                          \.string),
        ("`[^`\\n]*`",                          [],                          \.string),
        (keywordPattern,                        [],                          \.keyword),
        (#"\b0x[0-9a-fA-F]+\b"#,               [],                          \.number),
        (#"\b\d+\.?\d*([eE][+-]?\d+)?\b"#,     [],                          \.number),
        (#"\b[a-z_][a-zA-Z0-9_]*(?=\s*\()"#,   [],                          \.function_),
        (#"\b[A-Z][a-zA-Z0-9_]+\b"#,           [],                          \.typeName),
    ]

    private static let keywordPattern: String = {
        // Longer keywords first to prevent partial matches
        let kws = keywords.sorted { $0.count > $1.count }
        return #"\b("# + kws.map { NSRegularExpression.escapedPattern(for: $0) }.joined(separator: "|") + #")\b"#
    }()

    // MARK: - Keywords (Swift · Python · JS/TS · Go · Rust · Kotlin)

    private static let keywords: [String] = [
        // Swift
        "func", "let", "var", "class", "struct", "enum", "protocol", "extension",
        "if", "else", "guard", "switch", "case", "default", "for", "while", "repeat",
        "return", "break", "continue", "throw", "throws", "rethrows", "try", "catch", "do",
        "import", "typealias", "where", "in", "is", "as", "true", "false", "nil",
        "self", "super", "static", "final", "override", "public", "private", "internal",
        "fileprivate", "open", "async", "await", "init", "deinit", "lazy", "weak",
        "unowned", "mutating", "inout", "some", "any", "actor",
        // Python
        "def", "elif", "except", "finally", "from", "lambda", "nonlocal", "pass",
        "raise", "with", "yield", "None", "True", "False", "and", "or", "not",
        "global", "assert", "del",
        // JS / TS
        "const", "function", "new", "this", "typeof", "instanceof", "void",
        "null", "undefined", "of", "export", "interface", "type", "readonly",
        "abstract", "implements", "extends", "namespace", "declare",
        // Go
        "package", "chan", "go", "select", "defer", "range", "make", "map",
        // Rust
        "fn", "mut", "pub", "use", "mod", "impl", "trait", "match", "loop",
        "move", "ref", "dyn", "crate", "unsafe", "extern",
        // Kotlin / general
        "fun", "val", "when", "object", "companion", "data", "sealed",
        "constructor", "get", "set",
    ]

    // MARK: - Themes

    struct Theme {
        let text: NSColor
        let keyword: NSColor
        let string: NSColor
        let comment: NSColor
        let number: NSColor
        let function_: NSColor
        let typeName: NSColor

        // GitHub Light
        static let light = Theme(
            text:      .init(srgbHex: 0x24292f),
            keyword:   .init(srgbHex: 0xcf222e),
            string:    .init(srgbHex: 0x0a3069),
            comment:   .init(srgbHex: 0x6e7781),
            number:    .init(srgbHex: 0x0550ae),
            function_: .init(srgbHex: 0x8250df),
            typeName:  .init(srgbHex: 0x953800)
        )

        // GitHub Dark
        static let dark = Theme(
            text:      .init(srgbHex: 0xe6edf3),
            keyword:   .init(srgbHex: 0xff7b72),
            string:    .init(srgbHex: 0xa5d6ff),
            comment:   .init(srgbHex: 0x8b949e),
            number:    .init(srgbHex: 0x79c0ff),
            function_: .init(srgbHex: 0xd2a8ff),
            typeName:  .init(srgbHex: 0xffa657)
        )
    }
}

private extension NSColor {
    convenience init(srgbHex h: UInt32) {
        self.init(srgbRed: CGFloat((h >> 16) & 0xff) / 255,
                  green:   CGFloat((h >>  8) & 0xff) / 255,
                  blue:    CGFloat( h        & 0xff) / 255,
                  alpha:   1)
    }
}
