# Lotus
A complete web framework for Ruby

## v0.2.1 - 2015-02-06
### Added
- [Huy Do] Introduced `Lotus::Logger`
- [Jimmy Zhang] `lotus new` accepts a `--path` argument
- [Jimmy Zhang] Application generator for the current directory (`lotus new .`). This is useful to provide a web deliverable for existing Ruby gems.
- [Trung Lê] Add example mapping file for application generator: `lib/config/mapping.rb`
- [Hieu Nguyen] RSpec support for application generator: `--test=rspec` or `--test=minitest` (default)

### Fixed
- [Rob Yurkowski] Ensure application name doesn't contain special or forbidden characters.
- [Luca Guidi] Ensure all the applications are loaded in console
- [Trung Lê] Container architecture: preload only `lib/<appname>/**/*.rb`
- [Hieu Nguyen] Fixed `lotus new` to print usage when application name isn't provided

## v0.2.0 - 2014-06-23
### Added
- [Luca Guidi] Introduced `lotus new` as a command to generate applications. It supports "container" architecture for now.
- [Luca Guidi] Show a welcome page when the application doesn't have routes
- [Luca Guidi] Introduced `Lotus::Application.preload!` to preload all the Lotus applications in a given Ruby process. (Bulk `Lotus::Application.load!`)
- [Trung Lê] Allow browsers to fake non `GET`/`POST` requests via `Rack::MethodOverride`
- [Josue Abreu] Allow to define body parses for non `GET` HTTP requests (`body_parsers` configuration)
- [Alfonso Uceda Pompa] Allow to toggle static assets serving (`serve_assets` configuration)
- [Alfonso Uceda Pompa] Allow to serve assets from multiple sources (`assets` configuration)
- [Luca Guidi] Allow to configure `ENV` vars with per environment `.env` files
- [Alfonso Uceda Pompa] Introduced `lotus routes` command
- [Luca Guidi] Allow to configure low level settings for MVC frameworks (`model`, `view` and `controller` configuration)
- [Luca Guidi] Introduced `Lotus::Container`
- [Trung Lê] Include `Lotus::Presenter` as part of the duplicated modules
- [Trung Lê] Include `Lotus::Entity` and `Lotus::Repository` as part of the duplicated modules
- [Luca Guidi] Introduced code reloading for `lotus server`
- [Trung Lê] Allow to configure database adapter (`adapter` configuration)
- [Luca Guidi & Trung Lê] Allow to configure database mapping (`mapping` configuration)
- [Piotr Kurek] Introduced custom templates for non successful responses
- [Luca Guidi] Allow to configure exceptions handling (`handle_exceptions` configuration)
- [Michal Muskala] Allow to configure sessions (`sessions` configuration)
- [Josue Abreu] Allow to configure cookies (`cookies` configuration)
- [Piotr Kurek] Allow to yield multiple configurations per application, according to the current environment
- [David Celis] Allow to configure Rack middleware stack (`middleware` configuration)
- [David Celis] Introduced `lotus console` command. It runs the REPL configured in `Gemfile` (eg. pry or ripl). Defaults to IRb.
- [Luca Guidi] Introduced `Lotus::Environment` which holds the informations about the current environment, and CLI arguments
- [Luca Guidi] Introduced `Lotus::Application.load!` to load and configure an application without requiring user defined code (controllers, views, etc.)
- [Leonard Garvey] Introduced `lotus server` command. It runs the application with the Rack server declared in `Gemfile` (eg. puma, thin, unicorn). It defaults to `WEBRick`.
- [Luca Guidi] Official support for MRI 2.1 and 2.2

### Changed
- [Alfonso Uceda Pompa] Changed semantic of `assets` configuration. Now it's only used to set the sources for the assets. Static serving assets has now a new configuration: `serve_assets`.

### Fixed
- [Luca Guidi] Ensure `HEAD` requests return empty body

## v0.1.0 - 2014-06-23
### Added
- [Luca Guidi] Allow to run multiple Lotus applications in the same Ruby process (framework duplication)
- [Luca Guidi] Introduced `Lotus::Routes` as factory to generate application URLs
- [Luca Guidi] Allow to configure scheme, host and port (`scheme`, `host` and `port` configuration)
- [Luca Guidi] Allow to configure a layout to use for all the views of an application (`layout` configuration)
- [Luca Guidi] Allow to configure routes (`routes` configuration)
- [Luca Guidi] Allow to configure several load paths for Ruby source files (`load_paths` configuration)
- [Luca Guidi] Allow to serve static files (`assets` configuration)
- [Luca Guidi] Render default pages for non successful responses (eg `404` or `500`)
- [Luca Guidi] Allow to configure the root of an application (`root` configuration)
- [Luca Guidi] Introduced `Lotus::Configuration`
- [Luca Guidi] Introduced `Lotus::Application`
- [Luca Guidi] Official support for MRI 2.0
