# Hanami

The web, with simplicity.

## Frameworks

Hanami combines small yet powerful frameworks:

* [**Hanami::Utils**](https://github.com/hanami/utils) - Ruby core extensions and class utilities
* [**Hanami::Router**](https://github.com/hanami/router) - Rack compatible HTTP router for Ruby
* [**Hanami::Validations**](https://github.com/hanami/validations) - Validations mixin for Ruby objects
* [**Hanami::Helpers**](https://github.com/hanami/helpers) - View helpers for Ruby applications
* [**Hanami::Mailer**](https://github.com/hanami/mailer) - Mail for Ruby applications
* [**Hanami::Model**](https://github.com/hanami/model) - Persistence with entities, repositories and data mapper
* [**Hanami::Assets**](https://github.com/hanami/assets) - Assets management for Ruby
* [**Hanami::View**](https://github.com/hanami/view) - Presentation with a separation between views and templates
* [**Hanami::Controller**](https://github.com/hanami/controller) - Full featured, fast and testable actions for Rack

These components are designed to be used independently or together in a Hanami application.
If you aren't familiar with them, please take time to go through their READMEs.

## Status

[![Gem Version](https://badge.fury.io/rb/hanami.svg)](http://badge.fury.io/rb/hanami)
[![Build Status](https://secure.travis-ci.org/hanami/hanami.svg?branch=master)](http://travis-ci.org/hanami/hanami?branch=master)
[![Coverage](https://coveralls.io/repos/hanami/hanami/badge.svg?branch=master)](https://coveralls.io/r/hanami/hanami)
[![Code Climate](https://codeclimate.com/github/hanami/hanami.svg)](https://codeclimate.com/github/hanami/hanami)
[![Dependencies](https://gemnasium.com/hanami/hanami.svg)](https://gemnasium.com/hanami/hanami)
[![Inline docs](http://inch-ci.org/github/hanami/hanami.svg)](http://inch-ci.org/github/hanami/hanami)

## Contact

* Home page: http://hanamirb.org
* Community: http://hanamirb.org/community
* Guides: http://hanamirb.org/guides
* Mailing List: http://hanamirb.org/mailing-list
* API Doc: http://rdoc.info/gems/hanami
* Bugs/Issues: https://github.com/hanami/hanami/issues
* Support: http://stackoverflow.com/questions/tagged/hanami
* Forum: https://discuss.hanamirb.org
* Chat: http://chat.hanamirb.org

## Rubies

__Hanami__ supports Ruby (MRI) 2+

## Installation

```shell
% gem install hanami
```

## Usage

```shell
% hanami new bookshelf
% cd bookshelf && bundle
% bundle exec hanami server # visit http://localhost:2300
```

Please follow along with the [Getting Started guide](http://hanamirb.org/guides/getting-started).

## Community

We strive for a Community made of **inclusive, helpful and smart people**.
We have a [Code of Conduct](http://hanamirb.org/community/#code-of-conduct) to handle controversial cases.
In general, we expect **you** to be **nice** with other people.
Our hope is for a great software and a great Community.

### Contributor Code of Conduct

As contributors and maintainers of this project, we pledge to respect all people who contribute through reporting issues, posting feature requests, updating documentation, submitting pull requests or patches, and other activities.

We are committed to making participation in this project a harassment-free experience for everyone, regardless of level of experience, gender, gender identity and expression, sexual orientation, disability, personal appearance, body size, race, ethnicity, age, or religion.

Examples of unacceptable behavior by participants include the use of sexual language or imagery, derogatory comments or personal attacks, trolling, public or private harassment, insults, or other unprofessional conduct.

Project maintainers have the right and responsibility to remove, edit, or reject comments, commits, code, wiki edits, issues, and other contributions that are not aligned to this Code of Conduct. Project maintainers who do not follow the Code of Conduct may be removed from the project team.

This code of conduct applies both within project spaces and in public spaces when an individual is representing the project or its community.

Instances of abusive, harassing, or otherwise unacceptable behavior may be reported by opening an issue or contacting one or more of the project maintainers.

This Code of Conduct is adapted from the Contributor Covenant, version 1.1.0, available from http://contributor-covenant.org/version/1/1/0/

## Contributing

1. Fork it ( https://github.com/hanami/hanami/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Versioning

__Hanami__ uses [Semantic Versioning 2.0.0](http://semver.org)

## Copyright

Copyright © 2014-2016 Luca Guidi – Released under MIT License
This project was formerly known as Lotus (`lotusrb`).
