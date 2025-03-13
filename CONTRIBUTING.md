# Contributing to Hanami

Thank you for your interest in contributing to Hanami! This document outlines the process for contributing, with tips to help you along the way.

## Code of Conduct

Everyone interacting with Hanami codebases, issue trackers, chat rooms, and forum is expected to follow our [Code of Conduct](./CODE_OF_CONDUCT.md).

## How to contribute

### Reporting issues

- Check [GitHub issues](https://github.com/issues?q=org%3Ahanami+is%3Aopen+is%3Aissue) to see if your issue has already been reported.
- If you don’t find an open issue, create a new one, either in [hanami/hanami](https://github.com/hanami/hanami/issues) or the [relevant repo](https://github.com/hanami).
  - Include a clear title and description.
  - Add as much relevant information as possible (such as your Hanami version,`Gemfile.lock`, Ruby version, OS, as well as code samples, error messages or stack traces).
  - Include steps or code to reproduce the issue.

### Fixing issues

We maintain a range of [“help wanted”](https://github.com/issues?q=org%3Ahanami+is%3Aopen+is%3Aissue+label%3A%22help+wanted%22) and [“good first issue”](https://github.com/issues?q=org%3Ahanami+is%3Aopen+is%3Aissue+label%3A%22good+first+issue%22) issues on GitHub. These are issues that we want to see addressed for Hanami, and are ready for you to work on.

Feel free to choose an issue that looks interesting to you. Ask questions in the issue if anything is not clear. Once your work on fixing the issue is under way, you can [submit a pull request](#submitting-pull-requests).

### Suggesting enhancements

If you have a significant enhancement to suggest:

- [Create a proposal topic on our forum](https://discourse.hanamirb.org/c/proposals/6) describing your enhancement.
- Explain why this enhancement might be useful, focusing on real world use cases.
- Consider how it fits with Hanami framework design, and how it might impact existing features or workflows.
- From there, we’ll discuss discuss your proposal with you if/how it should be built.

For smaller changes that are more easily demonstrated through code, feel free to [submit a pull request](#submitting-pull-requests).

We cannot add all suggested enhancements to Hanami, but we’re open to having constructive conversations with you about them, and learning from each other along the way.

### Submitting pull requests

When you submit a pull request, consider the following:

- Include tests for your change.
- Ensure tests are passing on CI (see the “Actions” tab for each repo).
- Add or update API documentation for your change.
- Update user guides and/or docs to reflect your change, via a pull request to [hanami/site](https://github.com/hanami/site).
- Add an entry to [CHANGELOG.md](./CHANGELOG.md) for your change.
- Follow the [conventions](#conventions) outlined below, plus any other idioms you see across the codebase.

If you need help with any of these, please ask! Once your pull request is ready, we’ll review your change and have a conversation with you about it.

## Development setup

After cloning the repo:

```bash
bundle install
npm install
```

To run the rests:

```bash
bundle exec rake
# or
bundle exec rspec
```

## Conventions

### Commit messages

Your pull request will be squashed into a single commit when merged. Break up your pull request into individual commits if it will help with review of the code.

One of your commits should contain what the message that will become the commit message for the merged pull request.

[Follow these guidelines](https://developer.vonage.com/en/blog/how-to-write-a-great-git-commit-message) for your commit messages. If in doubt, don’t worry too much, we can fix things when we merge your pull request.

### Changelog

When you’re making a change that Hanami users should know about, please update the `CHANGELOG.md`. We follow the [keep a changelog](https://keepachangelog.com) conventions for our changelogs.

New entries can go in the `## [Unreleased]` section at the top of the file. For example:

```md
## [Unreleased]

### Added

- Add "418 I'm a teapot" middleware for caffeine allergics (@jane_doe in #9999)

## [v2.2.1] - 2024-11-12

### Changed

- Depend on matching minor version of hanami-cli (a version spec of `"~> 2.2.1"` instead of `"~> 2.2"`). This ensures that future bumps to the minor version of hanami-cli will not be inadvertently installed on user machines (@timriley in #1471)
```

Feel free to take inspiration from existing changelog entries for how you format your own.

### API docs

We use [YARD](https://yardoc.org) for our API docs.

When adding or changing code, keep the API docs up to date. Only public API needs to be fully documented. Each API doc should include:

- A concise, one-line description, in present tense form (see [Ruby’s API docs](https://docs.ruby-lang.org/en/master/) for examples).
- Additional paragraphs of documentation as required.
- Examples (via the `@example`) if hepful.
- `@param` and `@return` tags
- An `@api` tag
- A `@since` tag, formatted as `@since x.x.x` if the expected release version is unknown.

See [`lib/hanami/slice.rb`](./lib/hanami/slice.rb) for good examples of our API docs.

## Questions?

We want to help you become a successful contributor to Hanami! If you have questions, please find us here:

- [Forum](https://discourse.hanamirb.org/)
- [Chat](https://discord.gg/KFCxDmk3JQ)
