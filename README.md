# Hanami :cherry_blossom:

The web, with simplicity.

## Version

**This branch contains the code for `hanami` 2.0.x.**

## Frameworks

Hanami is a **full-stack** Ruby web framework. It's made up of smaller, single-purpose libraries.

This repository is for the full-stack framework, which provides the glue that ties all the parts together:

* [**Hanami::Router**](https://github.com/hanami/router) - Rack compatible HTTP router for Ruby
* [**Hanami::Controller**](https://github.com/hanami/controller) - Full featured, fast and testable actions for Rack
* [**Hanami::View**](https://github.com/hanami/view) - Presentation with a separation between views and templates
* [**Hanami::Helpers**](https://github.com/hanami/helpers) - View helpers for Ruby applications
* [**Hanami::Mailer**](https://github.com/hanami/mailer) - Mail for Ruby applications
* [**Hanami::Assets**](https://github.com/hanami/assets) - Assets management for Ruby

These components are designed to be used independently or together in a Hanami application.

## Status

[![Gem Version](https://badge.fury.io/rb/hanami.svg)](https://badge.fury.io/rb/hanami)
[![CI](https://github.com/hanami/hanami/workflows/ci/badge.svg?branch=main)](https://github.com/hanami/hanami/actions?query=workflow%3Aci+branch%3Amain)
[![Depfu](https://badges.depfu.com/badges/ba000e0f69e6ef1c44cd3038caaa1841/overview.svg)](https://depfu.com/github/hanami/hanami?project=Bundler)

## Installation

__Hanami__ supports Ruby (MRI) 3.0+

```shell
gem install hanami
```

## Usage

```shell
hanami new bookshelf
cd bookshelf && bundle
bundle exec hanami server # visit http://localhost:2300
```

Please follow along with the [Getting Started guide](https://guides.hanamirb.org/getting-started/).

## Donations

You can give back to Open Source, by supporting Hanami development via [GitHub Sponsors](https://github.com/sponsors/hanami).

### Supporters

  * [Trung Lê](https://github.com/runlevel5)
  * [James Carlson](https://github.com/jxxcarlson)
  * [Creditas](https://www.creditas.com.br/)

## Contact

* Home page: http://hanamirb.org
* Community: http://hanamirb.org/community
* Guides: https://guides.hanamirb.org
* Snippets: https://snippets.hanamirb.org
* Mailing List: http://hanamirb.org/mailing-list
* API Doc: http://rdoc.info/gems/hanami
* Bugs/Issues: https://github.com/hanami/hanami/issues
* Stack Overflow: http://stackoverflow.com/questions/tagged/hanami
* Forum: https://discourse.hanamirb.org
* **Chat**: http://chat.hanamirb.org

## Community

We strive for an inclusive and helpful community. We have a [Code of Conduct](http://hanamirb.org/community/#code-of-conduct) to handle controversial cases. In general, we expect **you** to be **nice** with other people. Our hope is for a great software and a great Community.

## Contributing [![Open Source Helpers](https://www.codetriage.com/hanami/hanami/badges/users.svg)](https://www.codetriage.com/hanami/hanami)

1. Fork it ( https://github.com/hanami/hanami/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

In addition to contributing code, you can help to triage issues. This can include reproducing bug reports, or asking for vital information such as version numbers or reproduction instructions. If you would like to start triaging issues, one easy way to get started is to [subscribe to hanami on CodeTriage](https://www.codetriage.com/hanami/hanami).

### Development Requirements

  * Ruby >= 3.0
  * Bundler
  * Node.js (MacOS)

### Testing

In order to simulate installed gems on developers' computers, the build installs all the gems locally in `vendor/cache`, including `hanami` code from `lib/`.

**Before running a test, please make sure you have a fresh version of the code:**

```shell
bundle exec rspec spec/path/to/file_spec.rb
```

## Versioning

__Hanami__ uses [Semantic Versioning 2.0.0](http://semver.org)

## Copyright

Copyright © 2014-2022 Hanami Team – Released under MIT License.
