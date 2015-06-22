# Lotus

A complete web framework for Ruby

## Frameworks

Lotus combines small yet powerful frameworks:

* [**Lotus::Utils**](https://github.com/lotus/utils) - Ruby core extensions and class utilities
* [**Lotus::Router**](https://github.com/lotus/router) - Rack compatible HTTP router for Ruby
* [**Lotus::Validations**](https://github.com/lotus/validations) - Validation mixin for Ruby objects
* [**Lotus::Helpers**](https://github.com/lotus/helpers) - View helpers for Ruby applications
* [**Lotus::Model**](https://github.com/lotus/model) - Persistence with entities, repositories and data mapper
* [**Lotus::View**](https://github.com/lotus/view) - Presentation with a separation between views and templates
* [**Lotus::Controller**](https://github.com/lotus/controller) - Full featured, fast and testable actions for Rack

These components are designed to be used independently or together in a Lotus application.
If you aren't familiar with them, please take time to go through their READMEs.

## Status

[![Gem Version](https://badge.fury.io/rb/lotusrb.png)](http://badge.fury.io/rb/lotusrb)
[![Build Status](https://secure.travis-ci.org/lotus/lotus.png?branch=master)](http://travis-ci.org/lotus/lotus?branch=master)
[![Coverage](https://coveralls.io/repos/lotus/lotus/badge.png?branch=master)](https://coveralls.io/r/lotus/lotus)
[![Code Climate](https://codeclimate.com/github/lotus/lotus.png)](https://codeclimate.com/github/lotus/lotus)
[![Dependencies](https://gemnasium.com/lotus/lotus.png)](https://gemnasium.com/lotus/lotus)
[![Inline docs](http://inch-ci.org/github/lotus/lotus.png)](http://inch-ci.org/github/lotus/lotus)

## Contact

* Home page: http://lotusrb.org
* Community: http://lotusrb.org/community
* Guides: http://lotusrb.org/guides
* Mailing List: http://lotusrb.org/mailing-list
* API Doc: http://rdoc.info/gems/lotusrb
* Bugs/Issues: https://github.com/lotus/lotus/issues
* Support: http://stackoverflow.com/questions/tagged/lotus-ruby
* Forum: https://discuss.lotusrb.org
* Chat: http://chat.lotusrb.org

## Rubies

__Lotus__ supports Ruby (MRI) 2+

## Installation

```shell
% gem install lotusrb
```

## Usage

```shell
% lotus new bookshelf
% cd bookshelf && bundle
% bundle exec lotus server # visit http://localhost:2300
```

Please follow along with the [Getting Started guide](http://lotusrb.org/guides/getting-started).

## Community

We strive for a Community made of **inclusive, helpful and smart people**.
We have a [Code of Conduct](http://lotusrb.org/community/#code-of-conduct) to handle controversial cases.
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

1. Fork it ( https://github.com/lotus/lotus/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Versioning

__Lotus__ uses [Semantic Versioning 2.0.0](http://semver.org)

## Copyright

Copyright © 2014-2015 Luca Guidi – Released under MIT License
