Hanami is an open source project and we would love you to help us make it better.

## Reporting Issues

A well formatted issue is appreciated, and goes a long way in helping us help you.

* Make sure you have a [GitHub account](https://github.com/signup/free)
* Submit a [GitHub issue](./issues) by:
  * Clearly describing the issue
    * Provide a descriptive summary
    * Explain the expected behavior
    * Explain the actual behavior
    * Provide steps to reproduce the actual behavior
    * Provide your application's complete `Gemfile.lock` as text (in a [Gist](https://gist.github.com) for bonus points)
    * Any relevant stack traces

If you provide code, make sure it is formatted with the triple backticks (\`).

At this point, we'd love to tell you how long it will take for us to respond,
but we just don't know.

## Pull requests

We accept pull requests to Hanami for:

* Adding documentation
* Fixing bugs
* Adding new features

Not all features proposed will be added but we are open to having a conversation
about a feature you are championing.

Here's a quick guide:

1. Fork the repo.

2. Run the tests. This is to make sure your starting point works. Tests can be
run via `rake`

3. Create a new branch and make your changes. This includes tests for features!

4. Push to your fork and submit a pull request. For more information, see
[GitHub's pull request help section](https://help.github.com/articles/using-pull-requests/).

At this point you're waiting on us. Expect a conversation regarding your pull
request; Questions, clarifications, and so on.

Some things that will increase the chance that your pull request is accepted:

* Use Hanami idioms
* Include tests that fail without your code, and pass with it
* Update the documentation, guides, etc.

### Commit messages

Make sure you author meaningful commit messages which match existing commit
messages in style.

### Changelog

Please help us to keep the `CHANGELOG.md` files up to date. Add appropriate entries
using the same style as existing entries which should follow the [keep a changelog suggestions](https://keepachangelog.com).
New entries have to go in the top `[Unreleased]` section to be added if necessary:

```
# Hanami

The web, with simplicity.

## [Unreleased]

### Added

- [John Doe] Add "418 I'm a teapot" middleware for caffeine allergics (#9999)

## [v2.2.1] - 2024-11-12

### Changed

- [Tim Riley] Depend on matching minor version of hanami-cli (a version spec of `"~> 2.2.1"` instead of `"~> 2.2"`). This ensures that future bumps to the minor version of hanami-cli will not be inadvertently installed on user machines (#1471)
(...)
```

### YARD and @since

Make sure you document your code with appropriate [YARD comments](https://yardoc.org/).
Newly introduced constants and methods should feature a `@since` comment to keep track
of when they were added. If the release version is uncertain or unknown, use the
following placeholder instead which will be adjusted as part of the release preparations:

```
# @since x.x.x
```
