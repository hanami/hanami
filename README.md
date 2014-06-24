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

**If you're not familiar with those libraries, please read their READMEs first.**

### Architecture

Unlike the other Ruby web frameworks, it has a flexible conventions for the code structure.
Developers can arrange the layout of their projects as they prefer.
There is a suggested architecture that can be easily changed with a few settings.

Based on the experience on dozens of projects, Lotus encourages the use of Ruby namespaces.
In this way, growing code bases can be split without effort, avoiding monolithic applications.

Lotus has a smart **mechanism of duplication of its frameworks**, that allows multiple copy of a framework and multiple applications to run in the **same Ruby process**.
In other words, even small Lotus applications are ready to be split in separated deliverables, but they can safely coexist in the same heap space.

For instance, when a `Bookshelf::Application` is loaded, `Lotus::View` and `Lotus::Controller` are duplicated as `Bookshelf::View` and `Bookshelf::Controller`, in order to make their configurations completely independent from `Backend::Application` they may live in the same Ruby process.
So that, developers SHOULD include `Bookshelf::Controller` instead of `Lotus::Controller`.

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

  module Controllers
    module Home
      include Lotus::Controller

      action 'Index' do
        def call(params)
        end
      end
    end
  end

  module Views
    module Home
      class Index
        include Lotus::View

        def render
          'Hello'
        end
      end
    end
  end
end

run OneFile::Application.new
```

When the application is instantiated, it will also create `OneFile::Controllers` and `OneFile::Views` namespace, to incentivize the modularization of the resources.
Also, note how similar are the names of the action and of the view: `OneFile::Controllers::Home::Index` and `OneFile::Views::Home::Index`.
**This naming system is a Lotus convention and MUST be followed, or otherwise configured**.

#### Microservices architecture

```
test/fixtures/microservices
├── apps
│   ├── backend
│   │   ├── application.rb                  Backend::Application
│   │   ├── controllers
│   │   │   └── sessions.rb                 Backend::Controllers::Sessions::New, Create & Destroy
│   │   ├── public
│   │   │   ├── favicon.ico
│   │   │   ├── fonts
│   │   │   │   └── cabin-medium.woff
│   │   │   ├── images
│   │   │   │   └── application.jpg
│   │   │   ├── javascripts
│   │   │   │   └── application.js
│   │   │   └── stylesheets
│   │   │       └── application.css
│   │   ├── templates
│   │   │   ├── backend.html.erb
│   │   │   └── sessions
│   │   │       └── new.html.erb
│   │   └── views
│   │       ├── backend_layout.rb           Backend::Views::BackendLayout
│   │       └── sessions
│   │           ├── create.rb               Backend::Views::Sessions::Create
│   │           ├── destroy.rb              Backend::Views::Sessions::Destroy
│   │           └── new.rb                  Backend::Views::Sessions::New
│   └── frontend
│       ├── application.rb                  Frontend::Application
│       ├── assets
│       │   ├── favicon.ico
│       │   ├── fonts
│       │   │   └── cabin-medium.woff
│       │   ├── images
│       │   │   └── application.jpg
│       │   ├── javascripts
│       │   │   └── application.js
│       │   └── stylesheets
│       │       └── application.css
│       ├── controllers
│       │   └── sessions
│       │       ├── create.rb               Frontend::Controllers::Sessions::Create
│       │       ├── destroy.rb              Frontend::Controllers::Sessions::Destroy
│       │       └── new.rb                  Frontend::Controllers::Sessions::New
│       ├── templates
│       │   ├── frontend.html.erb
│       │   └── sessions
│       │       └── new.html.erb
│       └── views
│           ├── application_layout.rb       Frontend::Views::ApplicationLayout
│           └── sessions
│               ├── create.rb               Frontend::Views::Sessions::Create
│               ├── destroy.rb              Frontend::Views::Sessions::Destroy
│               └── new.rb                  Frontend::Views::Sessions::New
└── config.ru
```

As you can see, the code can be organized as you prefer. For instance, all the sessions actions for the backend are grouped in the same file,
while they're split in the case of the frontend app.

**This because Lotus doesn't have namespace-to-filename conventions, and doesn't have autoload paths.**
During the boot time it **recursively preloads all the classes from the specified directories.**

```ruby
# apps/backend/application.rb
require 'lotus'

module Backend
  class Application < Lotus::Application
    configure do
      load_paths << [
        'controllers',
        'views'
      ]

      layout :backend

      routes do
        resource :sessions, only: [:new, :create, :destroy]
      end
    end
  end
end

# All code under apps/backend/{controllers,views} will be loaded
```

```ruby
# config.ru
require_relative 'apps/frontend/application'
require_relative 'apps/backend/application'

run Lotus::Router.new {
  mount Backend::Application,  at: '/backend'
  mount Frontend::Application, at: '/'
}

# We use an instance of Lotus::Router to mount two Lotus applications
```

#### Modulized application

```
test/fixtures/furnitures
├── app
│   ├── controllers
│   │   └── furnitures
│   │       └── catalog_controller.rb       Furnitures::CatalogController::Index
│   ├── templates
│   │   ├── application.html.erb
│   │   └── furnitures
│   │       └── catalog
│   │           └── index.html.erb
│   └── views
│       ├── application_layout.rb           Furnitures::Views::ApplicationLayout
│       └── furnitures
│           └── catalog
│               └── index.rb                Furnitures::Catalog::Index
├── application.rb                          Furnitures::Application
└── public
    ├── favicon.ico
    ├── fonts
    │   └── cabin-medium.woff
    ├── images
    │   └── application.jpg
    ├── javascripts
    │   └── application.js
    └── stylesheets
        └── application.css
```

You may have noticed a different naming structure here, it's easily achieved with a few settings.

```ruby
# application.rb
require 'lotus'

module Furnitures
  class Application < Lotus::Application
    configure do
      layout :application
      routes do
        get '/', to: 'catalog#index'
      end

      load_paths << 'app'

      controller_pattern "%{controller}Controller::%{action}"
      view_pattern       "%{controller}::%{action}"
    end
  end
end
```

The patterns above, are indicating to Lotus the name structure that we want to use for our application.
The main actor of the HTTP layer is an action. Actions are classes grouped logically in the same module called controller.

For an incoming `GET` request to `/`, the router will look for a `CatalogController` with an `Index` action.
Once the action will be called, the control will pass to the view. Here the application will look for a `Catalog` module with an `Index` view.

**That two patters are interpolated at the runtime, with the controller/action informations passed by the router.**

#### Top level architecture

```
test/fixtures/information_tech
├── app
│   ├── controllers
│   │   └── hardware_controller.rb         HardwareController::Index
│   ├── templates
│   │   ├── app.html.erb
│   │   └── hardware
│   │       └── index.html.erb
│   └── views
│       ├── app_layout.rb                  AppLayout
│       └── hardware
│           └── index.rb                   Hardware::Index
├── application.rb                         InformationTech::Application
├── config
│   └── routes.rb
└── public
    ├── favicon.ico
    ├── fonts
    │   └── cabin-medium.woff
    ├── images
    │   └── application.jpg
    ├── javascripts
    │   └── application.js
    └── stylesheets
        └── application.css
```

While this architecture is technically possible, it's discouraged, because it pollutes the global namespace and it makes hard to split in several deliverables, once the code base will be big enough.

```ruby
# application.rb
require 'lotus'

module InformationTech
  class Application < Lotus::Application
    configure do
      namespace Object

      controller_pattern '%{controller}Controller::%{action}'
      view_pattern       '%{controller}::%{action}'

      layout :app

      load_paths << 'app'
      routes 'config/routes'
    end
  end
end

# We use Object, because it's the top level Ruby namespace.
```

### Conventions

* Lotus expects that controllers, actions and views to have a specific pattern (see Configuration for customizations)
* All the commands must be run from the root of the project. If this requirement cannot be satisfied, please hardcode the path with `Configuration#root`.
* The template name must reflect the name of the corresponding view: `Bookshelf::Views::Dashboard::Index` for `dashboard/index.html.erb`.
* All the static files are served by the internal Rack middleware stack.
* The application expects to find static files under `public/` (see `Configuration#assets`)
* If the public folder doesn't exist, it doesn't serve static files.

### Non-Conventions

* The application structure can be organized according to developer needs.
* No file-to-name convention: modules and classes can live in one or multiple files.
* No autoloading paths. They must be explicitly configured.

### Configuration

A Lotus application can be configured with a DSL that determines its behavior.

```ruby
require 'lotus'

module Bookshelf
  class Application < Lotus::Application
    configure do
      # Determines the root of the application (optional)
      # Argument: String, Pathname, defaults to Dir.pwd
      #
      root 'path/to/root'

      # The Ruby namespace where to lookup for actions and views (optional)
      # Argument: Module, Class, defaults to the application module (eg. Bookshelf)
      #
      namespace Object

      # The relative load paths where the application will recursively load the code (mandatory)
      # Argument: String, Array<String>, defaults to empty set
      #
      load_paths << [
        'app/controllers',
        'app/views'
      ]

      # The route set (mandatory)
      # Argument: Proc with the routes definition
      #
      routes do
        get '/', to: 'home#index'
      end

      # The route set (mandatory) (alternative usage)
      # Argument: A relative path where to find the routes definition
      #
      routes 'config/routes'

      # The layout to be used by all the views (optional)
      # Argument: A Symbol that indicates the name, default to nil
      #
      layout :application # Will look for Bookshelf::Views::ApplicationLayout

      # The relative path where to find the templates (optional)
      # Argument: A string with the relative path, default to the root of the app
      #
      templates 'app/templates'

      # Default format for the requests that don't specify an HTTP_ACCEPT header (optional)
      # Argument: A symbol representation of a mime type, default to :html
      #
      default_format :json

      # URI scheme used by the routing system to generate absoule URLs (optional)
      # Argument: A string, default to "http"
      #
      scheme 'https'

      # URI host used by the routing system to generate absoule URLs (optional)
      # Argument: A string, default to "localhost"
      #
      host 'bookshelf.org'

      # URI port used by the routing system to generate absoule URLs (optional)
      # Argument: An object coercible to integer, default to 80 if the scheme is http and 443 if it's https
      # This SHOULD be configured only in case the application listens to that non standard ports
      #
      port 2323

      # The name pattern to find controller and actions (optional)
      # Argument: A string, it must contain "%{controller}" and %{action}
      # Default to "Controllers::%{controller}::%{action}"
      #
      controller_pattern '%{controller}Controller::%{action}'

      # The name pattern to find views (optional)
      # Argument: A string, it must contain "%{controller}" and %{action}
      # Default to "Views::%{controller}::%{action}"
      #
      view_pattern '%{controller}Views::%{action}'
    end
  end
end
```

## The future

Lotus uses different approaches for web development with Ruby, for this reason, it needs to reach a certain code maturity degree.
It will be improved by collecting the feedback of real world applications.

Also, it still lacks features like: live reloading, multiple environments, code generators, cli, etc..
Please get involved with the project.

Thank you.

## Contributing

1. Fork it ( https://github.com/lotus/lotus/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Versioning

__Lotus__ uses [Semantic Versioning 2.0.0](http://semver.org)

## Copyright

Copyright 2014 Luca Guidi – Released under MIT License
