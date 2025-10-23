# Hanami :cherry_blossom:

**A flexible framework for maintainable Ruby apps.**

Hanami is a **full-stack** Ruby web framework. It's made up of smaller, single-purpose libraries.

This repository is for the full-stack framework, which provides the glue that ties all the parts together:

* [**Hanami::Router**](https://github.com/hanami/router) - Rack compatible HTTP router for Ruby
* [**Hanami::Controller**](https://github.com/hanami/controller) - Full featured, fast and testable actions for Rack
* [**Hanami::View**](https://github.com/hanami/view) - Presentation with a separation between views and templates
* [**Hanami::DB**](https://github.com/hanami/db) - Database integration, complete with migrations, repositories, relations, and structs
* [**Hanami::Assets**](https://github.com/hanami/assets) - Assets management for Ruby

These components are designed to be used independently or together in a Hanami application.

## Status

[![Gem Version](https://badge.fury.io/rb/hanami.svg)](https://badge.fury.io/rb/hanami)
[![CI](https://github.com/hanami/hanami/actions/workflows/ci.yml/badge.svg)](https://github.com/hanami/hanami/actions?query=workflow%3Aci+branch%3Amain)

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

## Donations

You can give back to Open Source, by supporting Hanami development via [GitHub Sponsors](https://github.com/sponsors/hanami).

## Contact

* [Home page](http://hanamirb.org)
* [Community](http://hanamirb.org/community)
* [Guides](https://guides.hanamirb.org)
* [Issues](https://github.com/hanami/hanami/issues)
* [Forum](https://discourse.hanamirb.org)
* [Chat](https://discord.gg/KFCxDmk3JQ)

## Community

We care about building a friendly, inclusive and helpful community. We welcome people of all backgrounds, genders and experience levels, and respect you all equally.

We do not tolerate nazis, transphobes, racists, or any kind of bigotry. See our [code of conduct](http://hanamirb.org/community/#code-of-conduct) for more.

## Contributing

1. Fork it ( https://github.com/hanami/hanami/fork )
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

### Development Requirements

* Ruby >= 3.2
* Bundler
* Node.js

## Versioning

Hanami uses [Semantic Versioning 2.0.0](http://semver.org).

## Copyright

Copyright © 2014–2025 Hanami Team – Released under MIT License.
