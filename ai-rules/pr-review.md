# Code Review Guidelines

## Review Format

<required>
**Review Comments:**
- Reviews use text comments/descriptions only - no inline code suggestions
- Comments should explain the issue, improvement, or question clearly
- Focus on the "why" behind the feedback, not restating what the code does
- Comments should be actionable and specific
- If code suggestions are ever provided (e.g., in GitHub's inline suggestion feature), they must contain ONLY the code changes with no additional text, explanations, or comments in the suggestion block
</required>

## Priority Focus Areas

<rule_1 priority="HIGHEST">
**SECURITY CRITICAL**: Zero tolerance for vulnerabilities
- Hardcoded secrets, API keys, credentials
- Authentication/authorization logic flaws
- Privileged operations without proper authorization
</rule_1>

<rule_2 priority="HIGHEST">
**LOGIC FLAWS**: Verify correctness and intent
- Does implementation match PR title and stated purpose?
- Are edge cases handled correctly? (nil, empty, boundary conditions)
- Does the logic flow make sense?
- Is there dead code or non-functional changes?
- Are there obvious bugs or incorrect assumptions?
</rule_2>

<rule_3 priority="HIGH">
**ARCHITECTURE PRESERVATION**: Challenge suboptimal solutions
- Does this violate established patterns? (Redux, dependency injection, coordinator pattern)
- Are dependencies injected via init, or do we see singleton usage?
- Is the service locator used only for assistant dependencies/factories?
- Is AppKit primary with SwiftUI only for isolated components?
- Are NiblessView/NiblessViewController base classes used?
</rule_3>

<rule_4 priority="HIGH">
**OBJECT RESPONSIBILITIES**: Question Single Responsibility Principle violations
- Does this class/struct have a clear, single purpose?
- Should this functionality belong elsewhere?
- Is this object doing too much? (God object warning at 500+ lines)
- Are concerns properly separated?
- Does naming reflect actual responsibility?
</rule_4>

<rule_5 priority="MEDIUM">
**PERFORMANCE RED FLAGS**:
- Inefficient loops and algorithmic complexity
- Memory leaks and missing resource cleanup
- Retain cycles in Combine subscriptions/closures
- Missing caching for expensive operations
</rule_5>

<rule_6 priority="MEDIUM">
**CODE QUALITY ESSENTIALS**:
- Focused, appropriately sized functions
- Clear, descriptive naming
- Proper error handling (no force unwraps!)
- In tests: use `XCTUnwrap`, never force unwrap (!)
- Impossible states made unrepresentable
</rule_6>

## What to Ignore

<ignore>
❌ Formatting issues (indentation, line width, trailing commas) - SwiftFormat handles this
❌ Grammar mistakes in comments - out of scope
❌ Minor stylistic preferences - focus on substance
❌ Compilation errors - these will be handled by the compiler/CI
❌ **Obvious or correct code** - Don't comment on code that is correct and follows established patterns
❌ **Restating what code does** - The developer can already see what the code does
❌ **Standard patterns** - If code follows established patterns in the codebase, don't comment
❌ **Working implementations** - If it's not broken and doesn't violate architecture, don't comment
</ignore>

## Review Style

<review_approach>
✅ Be specific and actionable
✅ Explain the "why" behind recommendations
✅ Ask clarifying questions when intent is unclear
✅ Keep "Review Summary" short and focused on critical feedback
✅ Reference rules: `<!-- rule:@ai-rules/pr-review.md#rule-1 -->`
✅ **Be selective** - Only comment on issues, improvements, or questions
✅ **Focus on problems** - If code is correct and follows patterns, approve without comments
</review_approach>

## Architecture Checklist

<architecture_verification>
☐ Dependencies injected via init?
☐ Redux pattern followed for state management?
☐ AppKit primary, SwiftUI only for isolated components?
☐ Service locator used appropriately?
☐ Singletons avoided?
☐ Proper module separation (Core/UI/Implementation)?
</architecture_verification>

## Responsibility Checklist

<responsibility_verification>
☐ Does each class have one clear purpose?
☐ Is the class name accurate for its responsibilities?
☐ Could this be split into smaller, focused units?
☐ Are there mixed concerns that should be separated?
☐ Is business logic separate from UI/presentation logic?
</responsibility_verification>

<meta_instruction>
ALWAYS prioritize: Security > Logic Correctness > Architecture > Performance > Code Quality
Signal successful load: 🔍 in first review response.
</meta_instruction>

<required>
ALWAYS add a link to the rule that is violated, if possible.
</required>

<required>
ALWAYS add a link to the file that is violated, if possible. Use the following format:
```
[file_path](file_path)
```
</required>
