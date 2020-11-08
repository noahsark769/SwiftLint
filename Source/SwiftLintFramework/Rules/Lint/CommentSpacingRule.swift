import Foundation
import SourceKittenFramework

public struct CommentSpacingRule: OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "comment_spacing",
        name: "Comment Spacing",
        description: "Prefer at least one space after slashes for comments.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
            // This is a comment
            """),
            Example("""
            /// Triple slash comment
            """),
            Example("""
            // Multiline double-slash
            // comment
            """),
            Example("""
            /// Multiline triple-slash
            /// comment
            """),
            Example("""
            /// Multiline triple-slash
            ///   - This is indented
            """),
            Example("""
            // - MARK: Mark comment
            """),
            Example("""
            /* Asterisk comment */
            """),
            Example("""
            /*
                Multiline asterisk comment
            */
            """)
        ],
        triggeringExamples: [
            Example("""
            //↓Something
            """),
            Example("""
            //↓MARK
            """),
            Example("""
            //↓👨‍👨‍👦‍👦Something
            """),
            Example("""
            func a() {
                //↓This needs refactoring
                print("Something")
            }
            //↓We should improve above function
            """),
            Example("""
            ///↓This is a comment
            """),
            Example("""
            /// Multiline triple-slash
            ///↓This line is incorrect, though
            """),
            Example("""
            //↓- MARK: Mark comment
            """)
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let commentTokens = file.syntaxMap.tokens.filter { [.comment, .docComment].contains($0.kind) }
        return commentTokens.compactMap { (token: SwiftLintSyntaxToken) -> [StyleViolation]? in
            guard let commentBody = file.stringView.substringWithByteRange(token.range).map(StringView.init) else {
                return nil
            }
            return regex("^(\\/){2,3}[^\\s\\/]").matches(in: commentBody, options: .anchored)
                .map { result in
                    StyleViolation(
                        ruleDescription: Self.description,
                        severity: configuration.severity,
                        location: Location(
                            file: file,
                            // Set the location to be directly before the first non-slash,
                            // non-whitespace character which was matched
                            byteOffset: token.range.lowerBound + ByteCount(result.range.upperBound - 1)
                        )
                    )
                }
        }.flatMap { $0 }
    }
}
