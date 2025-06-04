<!-- markdownlint-disable MD033 MD041 -->
<div align="center">

# FormLogger

![Swift Versions](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmarkbattistella%2FFormLogger%2Fbadge%3Ftype%3Dswift-versions)

![Platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmarkbattistella%2FFormLogger%2Fbadge%3Ftype%3Dplatforms)

![Licence](https://img.shields.io/badge/Licence-MIT-white?labelColor=blue&style=flat)

</div>

`FormLogger` is a drop-in SwiftUI-compatible manager for logging bugs, feature requests, and feedback - with flexible support for custom UI and backends. You can roll your own interface while leveraging the powerful `FormManager`. It’s designed to integrate with lightweight backends (like a Cloudflare Worker) that push issues to GitHub via their API.

## Features

- **Input validation:** Ensures title, description, and (optional) contact details are properly filled and formatted.
- **Customisable view model:** Use the underlying `FormManager` to power your own UI with full control over behaviour.
- **Repository routing:** Supports single, multiple, or selectively overridden repositories based on form type.
- **Log attachment:** Automatically collects and submits log data alongside user input for better context.
- **Async submission:** Handles network requests using `async`/`await`, with detailed progress and error state handling.

## Installation

Add `FormLogger` to your Swift project using Swift Package Manager.

```swift
dependencies: [
  .package(url: "https://github.com/markbattistella/FormLogger", from: "1.0.0")
]
```

Alternatively, you can add `FormLogger` using Xcode by navigating to `File > Add Packages` and entering the package repository URL.

## Usage

With full control you can leverage the `FormManager` to power your own interface:

### Capabilities

- `userInput`: Contains title, description, and optional contact info.
- `formType`: Enum of `.bug`, `.feature`, or `.feedback`.
- `isFormValid`: Boolean indicating if user input is valid.
- `isProcessing`: Boolean showing if submission is ongoing.
- `submit()`: Async method that validates, collects logs, and sends to backend.
- `currentProgress`: Double value from 0–1 for progress.
- `currentProgressLabel`: String description of current progress state.

## Configuration

You can customise how form submissions are routed to repositories using the `RepositoryResolver`.

This modular setup ensures you can scale your feedback system as your project grows - from a single inbox to a fully segmented triage workflow.

There are three main strategies depending on your needs:

### Single Repository

Use a single repository for all form types - bugs, features, and feedback. This is a great setup if you're just starting out or want to centralise everything in one place.

```swift
let singleRepoConfig = PreviewFormConfig(
  repository: .single(
    Repository(
      username: "markbattistella",
      repository: "feedback-logger"
    )
  )
)
```

In this setup, all issues - regardless of type - are submitted to the same repository. It's simple, clean, and requires minimal setup.

### Multiple Repositories

Use different repositories depending on the type of form being submitted. Ideal when you want to separate concerns, visibility, or contributor access.

```swift
let multiRepoConfig = PreviewFormConfig(
  repository: .multiple([
    .bug: Repository(
      username: "markbattistella",
      repository: "bug-tracker"
    ),
    .feature: Repository(
      username: "markbattistella",
      repository: "feature-requests"
    ),
    .feedback: Repository(
      username: "markbattistella",
      repository: "feedback-logger"
    )
  ])
)
```

This gives you fine-grained control:

- Bugs could be logged to a private internal repo.
- Feedback might go to a public or community-accessible submodule.
- Feature requests could be tracked openly so others can view and upvote them.

### Partial Override

Start with a shared repository for all form types, but selectively override one or two categories. Great for workflows where most issues can be public, but certain categories (like bugs) need privacy.

```swift
let overrideRepoConfig = PreviewFormConfig(
  repository: .partial(
    shared: Repository(
      username: "markbattistella",
      repository: "feedback-logger"
    ),
    overrides: [
      .bug: Repository(
        username: "markbattistella",
        repository: "bugs-internal"
      )
    ]
  )
)
```

Perfect when:

- Feedback and feature requests are sent to a public-facing repo.
- Bug reports go to a private, locked-down internal repo accessible only to your team.

## Validation

Before submission, `FormManager` checks the user’s input for completeness and correctness. If validation fails, it throws a `FormValidationError`.

```swift
public struct FormValidationError: Error {
  public let invalidFields: Set<FormField>
}
```

Each invalid field is represented by a `FormField` enum, making it easy to highlight or handle specific errors in your UI.

Validation covers:

- **Title:** Cannot be empty or just whitespace.
- **Description:** Required, trimmed, and validated.
- **Contact Info:** Optional, but if enabled, both name and email must be valid.
  - Email format is checked using a *very* basic regex pattern.

You can access validation state live via:

```swift
viewModel.isFormValid // Bool
```

Or if you wish to get the invalid fields for display you can access `fieldErrors`:

```swift
// example
if let error = viewModel.fieldErrors[.title] {
  Text(error)
    .font(.caption)
    .foregroundColor(.red)
}
```

### HTTP Response Handling

When a form is submitted, the backend response is captured as a `FormResponse`, which conforms to `Error`.

```swift
public enum FormResponse: Error {
  case badRequest         // 400
  case unauthorized       // 401
  case serverError        // 500
  case unexpectedError    // any other failure
  case successMessage     // 200–299 success
}
```

## Backend System

While `FormLogger` is backend-agnostic, it's built to work beautifully with lightweight systems.

> [!CAUTION]
> The log file sent in the multipart form is GZIP-compressed and saved with a `.gz` extension. It must be decompressed on the backend using a GZIP-compatible decompression method.

### What I used

I’ve set mine up using:

- A GitHub App for API authentication
- A Cloudflare Worker to receive and forward form data
- Logs and metadata are submitted as a multipart form

<!-- > [!TIP] -->
<!-- > I wrote about [my setup](https://markbattistella.com/<TO-FILL>) and how to set your own up. -->

This lets me forward validated SwiftUI form data directly to GitHub as an issue — but you can use any backend that accepts JSON and logs.

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request for any features, fixes, or improvements.

## License

`FormLogger` is available under the MIT license. See the LICENSE file for more information.
