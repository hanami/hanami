[![Gem Version](https://badge.fury.io/rb/hanami.svg)](http://badge.fury.io/rb/hanami)
[![Build Status](https://secure.travis-ci.org/hanami/hanami.svg?branch=master)](http://travis-ci.org/hanami/hanami?branch=master)
[![Coverage](https://coveralls.io/repos/hanami/hanami/badge.svg?branch=master)](https://coveralls.io/r/hanami/hanami)
[![Code Climate](https://codeclimate.com/github/hanami/hanami.svg)](https://codeclimate.com/github/hanami/hanami)
[![Inline docs](http://inch-ci.org/github/hanami/hanami.svg)](http://inch-ci.org/github/hanami/hanami)

# Hanami :cherry_blossom:

The web, with simplicity.

## Frameworks

Hanami is a **full-stack** Ruby web framework.
It's made up of smaller, single-purpose libraries.

This repository is for the full-stack framework,
which provides the glue that ties all the parts together:

* [**Hanami::Model**](https://github.com/hanami/model) - Persistence with entities, repositories and data mapper
* [**Hanami::View**](https://github.com/hanami/view) - Presentation with a separation between views and templates
* [**Hanami::Controller**](https://github.com/hanami/controller) - Full featured, fast and testable actions for Rack
* [**Hanami::Validations**](https://github.com/hanami/validations) - Validations mixin for Ruby objects
* [**Hanami::Router**](https://github.com/hanami/router) - Rack compatible HTTP router for Ruby
* [**Hanami::Helpers**](https://github.com/hanami/helpers) - View helpers for Ruby applications
* [**Hanami::Mailer**](https://github.com/hanami/mailer) - Mail for Ruby applications
* [**Hanami::Assets**](https://github.com/hanami/assets) - Assets management for Ruby
* [**Hanami::CLI**](https://github.com/hanami/cli) - Ruby command line interface
* [**Hanami::Utils**](https://github.com/hanami/utils) - Ruby core extensions and class utilities

These components are designed to be used independently or together in a Hanami application.

## Installation
__Hanami__ supports Ruby (MRI) 2.3+

```shell
gem install hanami
```

## Usage

```shell
hanami new bookshelf
cd bookshelf && bundle
bundle exec hanami server # visit http://localhost:2300
```

Please follow along with the [Getting Started guide](http://hanamirb.org/guides/getting-started).

## Donations

You can give back to Open Source, by supporting Hanami development via a [donation](https://salt.bountysource.com/teams/hanami). :green_heart:

### Supporters

  * [Trung Lê](https://github.com/joneslee85)
  * [James Carlson](https://github.com/jxxcarlson)
  * [Creditas](https://www.creditas.com.br/)

## Contact

* Home page: http://hanamirb.org
* Community: http://hanamirb.org/community
* Guides: http://hanamirb.org/guides
* Mailing List: http://hanamirb.org/mailing-list
* API Doc: http://rdoc.info/gems/hanami
* Bugs/Issues: https://github.com/hanami/hanami/issues
* Stack Overflow: http://stackoverflow.com/questions/tagged/hanami
* Forum: https://discourse.hanamirb.org
* **Chat**: http://chat.hanamirb.org

## Community

We strive for an inclusive and helpful community.
We have a [Code of Conduct](http://hanamirb.org/community/#code-of-conduct) to handle controversial cases.
In general, we expect **you** to be **nice** with other people.
Our hope is for a great software and a great Community.

## Contributing [![Open Source Helpers](https://www.codetriage.com/hanami/hanami/badges/users.svg)](https://www.codetriage.com/hanami/hanami)

1. Fork it ( https://github.com/hanami/hanami/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

In addition to contributing code, you can help to triage issues. This can include reproducing bug reports, or asking for vital information such as version numbers or reproduction instructions. If you would like to start triaging issues, one easy way to get started is to [subscribe to hanami on CodeTriage](https://www.codetriage.com/hanami/hanami).

### How To Use Hanami HEAD

If you want to test Hanami's HEAD to try a new feature or to test a bug fix, here's how to do:

```
git clone https://github.com/hanami/hanami.git
cd hanami && bundle
bundle exec hanami new bookshelf --hanami-head
cd bookshelf
vim Gemfile # edit with: gem 'hanami', path: '..'
bundle
```

### Development Requirements

  * Ruby 2.3+ / JRuby 9.1.5.0+
  * Bundler
  * [PhantomJS](http://phantomjs.org/download.html)
  * Node.js (MacOS)

### Testing

In order to simulate installed gems on developers' computers, the build installs
all the gems locally in `vendor/cache`, including `hanami` code from `lib/`.

**Before running a test, please make sure you have a fresh version of the code:**

```shell
./script/setup
bundle exec rspec spec/path/to/file_spec.rb
```

To run all the tests, please use:

```shell
./script/ci
```

## Versioning

__Hanami__ uses [Semantic Versioning 2.0.0](http://semver.org)

## Copyright

Released under MIT License.

This project was formerly known as Lotus (`lotusrb`).

Copyright © 2014-2018 Luca Guidi.
