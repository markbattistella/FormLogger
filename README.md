<!-- markdownlint-disable MD033 MD041 -->
<div align="center">

# FormLogger

![Swift Versions](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmarkbattistella%2FFormLogger%2Fbadge%3Ftype%3Dswift-versions)

![Platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmarkbattistella%2FFormLogger%2Fbadge%3Ftype%3Dplatforms)

![Licence](https://img.shields.io/badge/Licence-MIT-white?labelColor=blue&style=flat)

</div>

`FormLogger` is a drop-in SwiftUI-compatible manager for logging bugs, feature requests, and feedback — with flexible support for custom UI and backends. You power the interface; `FormManager` handles validation, log collection, and async submission to a lightweight backend (such as a Cloudflare Worker that creates GitHub issues).

## Features

- **Input validation:** Ensures title, message, and optional contact details are properly filled and formatted.
- **Customisable view model:** Use `FormManager` to power your own UI with full control over behaviour.
- **Repository routing:** Supports single, multiple, or selectively overridden repositories based on form kind.
- **Log attachment:** Automatically collects and submits log data alongside user input for better context.
- **Async submission:** Handles network requests using `async`/`await`, with detailed progress and error state handling.

## Installation

Add `FormLogger` to your Swift project using Swift Package Manager.

```swift
dependencies: [
  .package(url: "https://github.com/markbattistella/FormLogger", from: "26.3.22")
]
```

### Requirements

- Swift 6.0+

## Usage

### FormManager

`FormManager` is a `@MainActor @Observable` class. Create one instance per form view and inject it as needed.

```swift
@State private var form = FormManager(config: MyFormConfig())
```

#### User-editable fields

```swift
form.title          // String
form.message        // String
form.contactName    // String
form.contactEmail   // String
form.kind           // FormManager.Kind — .bug, .feature, or .feedback
form.allowContact   // Bool
form.shouldCollectLogs // Bool
```

#### Read-only state

```swift
form.fieldErrors     // [FormManager.Field: String] — populated after validation
form.progressState   // FormManager.ProgressState — current submission lifecycle phase
form.isProcessing    // Bool — true while any operation is in progress
form.canSubmit       // Bool — true when validated and not processing
form.isFormValid     // Bool — true after a successful validation pass
form.messageCharacterLimit // Int — from FormConfiguration
```

#### Submission

```swift
do {
    try await form.submit()
} catch let error as FormManager.FormResponse {
    print(error.errorTitle)
    print(error.errorDescription ?? "")
} catch {
    print(error.localizedDescription)
}
```

`submit()` returns without throwing when validation fails — check `fieldErrors` or gate the call behind `canSubmit`. It throws a `FormManager.FormResponse` for network and server errors.

#### Metadata injection

Additional key-value pairs can be merged into the submission payload at runtime:

```swift
form.mergeMetadata(["appVersion": "2.1.0", "locale": Locale.current.identifier])
```

### Progress state

`FormManager.ProgressState` models each phase of submission and provides UI-friendly metadata:

```swift
ProgressView(value: form.progressState.progress) // 0.0 to 1.0
Text(form.progressState.displayMessage)           // e.g. "Submitting…"
```

States: `.idle`, `.exportingLogs`, `.submitting`, `.processingResponse`, `.clearingForm(timeRemaining:)`, `.completed`.

### Form kinds

`FormManager.Kind` is a `CaseIterable` enum with three cases:

```swift
Picker("Type", selection: $form.kind) {
    ForEach(FormManager.Kind.allCases) { kind in
        Label(kind.label, systemImage: kind.systemImage).tag(kind)
    }
}
```

Cases: `.bug`, `.feature`, `.feedback`. Each provides a localised `.label` and an SF Symbols `.systemImage`.

### Validation errors

After a failed `submit()`, field-specific messages are available in `fieldErrors`:

```swift
if let error = form.fieldErrors[.title] {
    Text(error).font(.caption).foregroundStyle(.red)
}
```

`FormManager.Field` cases: `.title`, `.message`, `.contactName`, `.contactEmail`.

You can also clear errors manually:

```swift
form.clearError(for: .title)
form.clearAllErrors()
```

## Configuration

Conform a type to `FormConfiguration` to control submission behaviour:

```swift
struct MyFormConfig: FormConfiguration {
    var apiURL: URL { URL(string: "https://worker.example.com/submit")! }
    var repository: Repository.Resolver {
        .single(Repository.GitHub(username: "markbattistella", repository: "feedback"))
    }
}
```

Optional properties have defaults:

| Property | Default |
| --- | --- |
| `characterLimit` | `500` |
| `shouldClearForm` | `true` |
| `clearFormDelay` | `.seconds(10)` |
| `customMetadata` | `nil` |
| `isDryRun` | `false` |

### Repository routing

#### Single repository

All form kinds route to one repository.

```swift
repository: .single(
    Repository.GitHub(username: "markbattistella", repository: "feedback")
)
```

#### Multiple repositories

A distinct repository per form kind. Every kind must be present or submission will crash at the missing entry.

```swift
repository: .multiple([
    .bug:      Repository.GitHub(username: "markbattistella", repository: "bug-tracker"),
    .feature:  Repository.GitHub(username: "markbattistella", repository: "feature-requests"),
    .feedback: Repository.GitHub(username: "markbattistella", repository: "feedback"),
])
```

#### Partial override

A shared fallback repository with optional per-kind overrides.

```swift
repository: .partial(
    shared: Repository.GitHub(username: "markbattistella", repository: "feedback"),
    overrides: [
        .bug: Repository.GitHub(username: "markbattistella", repository: "bugs-internal"),
    ]
)
```

### HTTP response errors

`FormManager.FormResponse` conforms to `LocalizedError` and maps server responses to user-facing messages:

| Case | Trigger |
| --- | --- |
| `.badRequest` | HTTP 400 |
| `.unauthorized` | HTTP 401 |
| `.forbidden` | HTTP 403 |
| `.serverError` | HTTP 500 |
| `.unexpectedStatus(Int)` | Any other status code |
| `.networkError(URLError)` | Network-level failure |

Each case provides `.errorTitle` (short headline) and `.errorDescription` (detail string).

## Backend

> [!CAUTION]
> The log file sent in the multipart form is GZIP-compressed with a `.gz` extension. Decompress it on the backend using a GZIP-compatible method.

FormLogger is backend-agnostic. The reference setup uses a GitHub App for API authentication and a Cloudflare Worker to receive and forward the multipart payload to GitHub as an issue.

> [!TIP]
> The full setup is documented in a four-part series: [part 1](https://markbattistella.com/writings/2025/rethinking-feedback-p1/), [part 2](https://markbattistella.com/writings/2025/rethinking-feedback-p2/), [part 3](https://markbattistella.com/writings/2025/rethinking-feedback-p3/), [part 4](https://markbattistella.com/writings/2025/rethinking-feedback-p4/).

## License

`FormLogger` is available under the MIT license. See the LICENCE file for more information.
