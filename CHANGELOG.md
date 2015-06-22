# Lotus
A complete web framework for Ruby

## v0.4.0 - 2015-06-23
### Added
- [Luca Guidi] Database migrations and new CLI commands for database operations
- [Luca Guidi] Cross Site Request Forgery (CSRF) protection
- [Hiếu Nguyễn & Luca Guidi] Application Architecture
- [Alfonso Uceda Pompa] Force SSL for applications
- [Luca Guidi] Introduced `--url` CLI argument for action generator
- [Luca Guidi] Added `rendered` "let" variable for new generated tests for views

### Fixed
- [Alfonso Uceda Pompa] Fix generated routes for Container applications mounted on a path different from `/`.
- [Luca Guidi] Reading `.lotusrc` pollutes `ENV` with unwanted variables.
- [Alfonso Uceda Pompa] Added sqlite extension to SQLite/SQLite3 database URL.

### Changed
- [Luca Guidi] `.env`, `.env.development` and `.env.test` are generated and expected to be placed at the root of the project.
- [Luca Guidi] Remove database mapping from generated apps.
- [Trung Lê & Luca Guidi] Remove default generated from new apps.
- [Luca Guidi] New application should depend on `lotus-model ~> 0.4`

## v0.3.2 - 2015-05-22
### Added
- [Alfonso Uceda Pompa] Automatic secure cookies if the current connection is using HTTPS.
- [Alfonso Uceda Pompa] Routing helpers for actions (via `#routes`).
- [My Mai] Introduced `Lotus.root`. It returns the top level directory of the project.

### Fixed
- [Ngọc Nguyễn] Model generator should use new RSpec syntax.
- [Ngọc Nguyễn] Model generator must respect file name conventions for Ruby.
- [Ngọc Nguyễn] Action generator must respect file name conventions for Ruby.
- [Alfonso Uceda Pompa] Action generator must raise error if name isn't provided.
- [Luca Guidi] Container generator for RSpec let the application to be preloaded (discard `config.before(:suite)`)

## v0.3.1 - 2015-05-15
### Added
- [Hiếu Nguyễn] Introduced application generator (eg. `bundle exec lotus generate app admin` creates `apps/admin`).
- [Ngọc Nguyễn] Introduced model generator (eg. `bundle exec lotus generate model user` creates entity, repository and test files).
- [Ngọc Nguyễn] Introduced `Lotus.env`, `Lotus.env?` for current environment introspection (eg. `Lotus.env?(:test)` or `Lotus.env?(:staging, :production)`)
- [Miguel Molina] Skip view creation when an action is generated via `--skip-view` CLI arg.

### Fixed
- [Luca Guidi] Ensure routes to be loaded for unit tests

## v0.3.0 - 2015-03-23
### Added
- [Luca Guidi] Introduced action generator. Eg. `bundle exec lotus generate action web dashboard#index`
- [Alfonso Uceda Pompa] Allow to specify default coookies options in application configuration. Eg. `cookies true, { domain: 'lotusrb.org' }`
- [Tom Kadwill] Include `Lotus::Helpers` in views.
- [Linus Pettersson] Allow to specify `--database` CLI option when generate a new application. Eg. `lotus new bookshelf --database=postgresql`
- [Linus Pettersson] Initialize a Git repository when generating a new application
- [Alfonso Uceda Pompa] Produce `.lotusrc` when generating a new application
- [Alfonso Uceda Pompa] Security HTTP headers. `X-Frame-Options` and `Content-Security-Policy` are now enabled by default.
- [Linus Pettersson] Database console. Run with `bundle exec lotus db console`
- [Luca Guidi] Dynamic finders for relative and absolute routes. It implements method missing: `Web::Routes.home_path` will resolve to `Web::Routes.path(:home)`.

### Changed
– [Alfonso Uceda Pompa] Cookies will send `HttpOnly` by default. This is for security reasons.
- [Jan Lelis] Enable `templates` configuration for new generated apps
- [Mark Connell] Change SQLite file extension from `.db` to `.sqlite3`

## v0.2.1 - 2015-02-06
### Added
- [Huy Đỗ] Introduced `Lotus::Logger`
- [Jimmy Zhang] `lotus new` accepts a `--path` argument
- [Jimmy Zhang] Application generator for the current directory (`lotus new .`). This is useful to provide a web deliverable for existing Ruby gems.
- [Trung Lê] Add example mapping file for application generator: `lib/config/mapping.rb`
- [Hiếu Nguyễn] RSpec support for application generator: `--test=rspec` or `--test=minitest` (default)

### Fixed
- [Luca Guidi] `lotus version` to previx `v` (eg `v0.2.1`)
- [Rob Yurkowski] Ensure application name doesn't contain special or forbidden characters
- [Luca Guidi] Ensure all the applications are loaded in console
- [Trung Lê] Container architecture: preload only `lib/<appname>/**/*.rb`
- [Hiếu Nguyễn] Fixed `lotus new` to print usage when application name isn't provided

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
