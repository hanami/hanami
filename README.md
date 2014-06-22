# Lotus

A complete web framework for Ruby

## Status

[![Gem Version](https://badge.fury.io/rb/lotusrb.png)](http://badge.fury.io/rb/lotusrb)
[![Build Status](https://secure.travis-ci.org/lotus/lotus.png?branch=master)](http://travis-ci.org/lotus/lotus?branch=master)
[![Coverage](https://coveralls.io/repos/lotus/lotus/badge.png?branch=master)](https://coveralls.io/r/lotus/lotus)
[![Code Climate](https://codeclimate.com/github/lotus/lotus.png)](https://codeclimate.com/github/lotus/lotus)
[![Dependencies](https://gemnasium.com/lotus/lotus.png)](https://gemnasium.com/lotus/lotus)
[![Inline docs](http://inch-ci.org/github/lotus/lotus.png)](http://inch-ci.org/github/lotus/lotus)

## Contact

* Home page: http://lotusrb.org
* Mailing List: http://lotusrb.org/mailing-list
* API Doc: http://rdoc.info/gems/lotusrb
* Bugs/Issues: https://github.com/lotus/lotus/issues
* Support: http://stackoverflow.com/questions/tagged/lotus-ruby
* Chat: https://gitter.im/lotus/chat

## Rubies

__Lotus__ supports Ruby (MRI) 2+

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'lotusrb'
```

And then execute:

```shell
$ bundle
```

Or install it yourself as:

```shell
$ gem install lotusrb
```

## Usage

Lotus combines the power and the flexibility of all its [frameworks](https://github.com/lotus).
It uses [Lotus::Router](https://github.com/lotus/router) and [Lotus::Controller](https://github.com/lotus/controller) for routing and controller layer, respectively.
While [Lotus::View](https://github.com/lotus/view) it's used for the presentational logic.

### Architecture

Unlike the other Ruby web frameworks, it has a flexible conventions for the code structure.
Developers can arrange the layout of their projects as they prefer.
There is a suggested architecture that can be easily changed with a few settings.

Based on the experience on dozens of projects, Lotus encourages the use of Ruby namespaces.
In this way, growing code bases can be split without effort, avoiding monolithic applications.

Lotus has a smart **mechanism of duplication of its frameworks**, that allows multiple copy of a framework and multiple applications to run in the same Ruby process.
In other words, even small Lotus applications are ready to be split in separated deliverables, but they can safely coexist in the same heap space.
For instance, when a `Bookshelf::Application` is loaded, `Lotus::View` and `Lotus::Controller` are duplicated as `Bookshelf::View` and `Bookshelf::Controller`, in order to make their configurations completely indepentend from `Backend::Application` thay may live in the same Ruby process.
So that, developers should include `Bookshelf::Controller` instead of `Lotus::Controller`.

#### One file application

```ruby
# config.ru

require 'lotus'

module OneFile
  class Application < Lotus::Application
    configure do
      routes do
        get '/', to: 'home#index'
      end
    end
  end

  module Controllers::Home
    include OneFile::Controller

    action 'Index' do
      def call(params)
        self.body = 'Hello'
      end
    end
  end
end

run OneFile::Application.new
```

## Contributing

1. Fork it ( https://github.com/lotus/lotus/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Versioning

__Lotus::Controller__ uses [Semantic Versioning 2.0.0](http://semver.org)

## Copyright

Copyright 2014 Luca Guidi – Released under MIT License
