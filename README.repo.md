**A flexible framework for maintainable Ruby apps.**

Hanami is a **full-stack** Ruby web framework. It's made up of smaller, single-purpose libraries.

This repository is for the full-stack framework, which provides the glue that ties all the parts together:

* [**Hanami::Router**](https://github.com/hanami/router) - Rack compatible HTTP router for Ruby
* [**Hanami::Controller**](https://github.com/hanami/controller) - Full featured, fast and testable actions for Rack
* [**Hanami::View**](https://github.com/hanami/view) - Presentation with a separation between views and templates
* [**Hanami::DB**](https://github.com/hanami/db) - Database integration, complete with migrations, repositories, relations, and structs
* [**Hanami::Assets**](https://github.com/hanami/assets) - Assets management for Ruby

These components are designed to be used independently or together in a Hanami application.

## Installation

```shell
gem install hanami
```

## Usage

```shell
hanami new bookshelf
cd bookshelf && bundle
bundle exec hanami dev
# Now visit http://localhost:2300
```

Please follow along with the [Getting Started guide](https://guides.hanamirb.org/getting-started/).

## Contributing

1. Fork it (https://github.com/hanami/hanami/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

In addition to contributing code, you can help to triage issues. This can include reproducing bug reports, or asking for vital information such as version numbers or reproduction instructions. If you would like to start triaging issues, one easy way to get started is to [subscribe to hanami on CodeTriage](https://www.codetriage.com/hanami/hanami).

### Tests

To run all test suite:

```shell
$ bundle exec rake
```

To run all the unit tests:

```shell
$ bundle exec rspec spec/unit
```

To run all the integration tests:

```shell
$ bundle exec rspec spec/integration
```

To run a single test:

```shell
$ bundle exec rspec path/to/spec.rb
```
