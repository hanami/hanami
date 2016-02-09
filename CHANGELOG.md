# Hanami
The web, with simplicity.

## v0.8.0 - (unreleased)
### Changed
– [Luca Guidi] Drop support for Ruby 2.0 and 2.1
- [Sean Collins] Add `--version` and `-v` for `hanami version` CLI

## v0.7.2 - 2016-02-09
### Fixed
- [Alfonso Uceda Pompa] Fixed routing issue when static assets server tried to hijiack paths that are matching directories in public directory

## v0.7.1 - 2016-02-05
### Fixed
- [Anton Davydov] Fixed routing issue when static assets server tried to hijiack requests belonging to dynamic endpoints
- [Anatolii Didukh] Ensure to fallback to default engine for `hanami console`

## v0.7.0 - 2016-01-22
### Changed
- [Luca Guidi] Renamed the project

## v0.6.1 - 2016-01-19
### Fixed
- [Anton Davydov] Show the current app name in Welcome page (eg. `/admin` shows instructions on how to generate an action for `Admin` app)
- [Anton Davydov] Fix project creation when name contains dashes (eg. `"awesome-project" => "AwesomeProject"`)
- [Anton Davydov] Ensure to add assets related entries to `.gitignore` when a project is generated with the `--database` flag
- [deepj] Avoid blank lines in generated `Gemfile`
- [trexnix] Fix for `lotus destroy app`: it doesn't cause a syntax error in `config/application.rb` anymore
- [Serg Ikonnikov & Trung Lê] Ensure console to use the bundled engine

## v0.6.0 - 2016-01-12
### Added
- [Luca Guidi] Introduced configurable assets compressors
- [Luca Guidi] Introduced "CDN mode" in order to serve static assets via Content Distribution Networks
- [Luca Guidi] Introduced "Digest mode" in production in order to generate and serve assets with checksum suffix
- [Luca Guidi] Introduced `lotus assets precompile` command to precompile, minify and append checksum suffix to static assets
- [Luca Guidi] Send `Content-Cache` HTTP header when serving static assets in production mode
- [Luca Guidi] Support new env var `SERVE_STATIC_ASSETS="true"` in order to serve static assets for the entire project
- [Luca Guidi] Generate new applications by including `Web::Assets::Helpers` in `view.prepare` block
- [Luca Guidi] Introduced new Rake tasks `:preload` and `:environment`
- [Luca Guidi] Introduced new Rake tasks `db:migrate` and `assets:precompile` for Rails/Heroku compatibility
- [Tadeu Valentt & Lucas Allan Amorin] Added `lotus destroy` command for apps, models, actions, migrations and mailers
- [Lucas Allan Amorim] Custom initializers (`apps/web/config/initializers`) they are ran when the project is loaded and about to start
- [Trung Lê] Generate mailer templates directory for new projects (eg. `lib/bookshelf/mailers/templates`)
- [Tadeu Valentt] Alias `--database` as `-d` for `lotus new`
- [Tadeu Valentt] Alias `--arch` as `-a` for `lotus new`
- [Sean Collins] Let `lotus generate action` to guess HTTP method (`--method` arg) according to RESTful conventions
- [Gonzalo Rodríguez-Baltanás Díaz] Generate new applications with default favicon

### Fixed
- [Neil Matatall] Use "secure compare" for CSRF tokens in order to prevent timing attacks
- [Bernardo Farah] Fix support for chunked response body (via `Rack::Chunked::Body`)
- [Lucas Allan Amorim] Add `bundler` as a runtime dependency
- [Lucas Allan Amorim] Ensure to load properly Bundler dependencies when starting the application
- [Luca Guidi] Ensure sessions to be always available for other middleware in Rack stack of single applications
- [Ken Gullaksen] Ensure to specify `LOTUS_PORT` env var from `.env`
- [Andrey Deryabin] Fix `lotus new .` and prevent to generate the project in a subdirectory of current one
- [Jason Charnes] Validate entity name for model generator
- [Caius Durling] Fixed generator for nested actions (eg. `lotus generate action web domains/certs#index`)
- [Tadeu Valentt] Prevent to generate migrations with the same name
- [Luca Guidi] Ensure RSpec examples to be generated with `RSpec.describe` instead of only `describe`
- [Andrey Deryabin] Avoid `lotus` command to generate unnecessary `.lotusrc` files
- [Jason Charnes] Convert camel case application name into snake case when generating actions (eg. `BeautifulBlossoms` to `beautiful_blossoms`)
- [Alfonso Uceda Pompa] Convert dasherized names into underscored names when generating projects (eg. `awesome-project` to `awesome_project`)

### Changed
- [Sean Collins] Welcome page shows current year in copyright notes
- [Luca Guidi] Add `/public/assets*` to `.gitignore` of new projects
- [Luca Guidi] Removed support for `default_format` in favor of `default_request_format`
- [Luca Guidi] Removed support for `apps/web/public` in favor of `apps/web/assets` as assets sources for applications
- [Luca Guidi] Removed support for `serve_assets` for single applications in order to global static assets server enabled via `SERVE_STATIC_ASSETS` env var
- [Luca Guidi] `assets` configuration in `apps/web/application.rb` now accepts a block to configure sources and other settings

## v0.5.0 - 2015-09-30
### Added
- [Ines Coelho & Rosa Faria] Introduced mailers support
- [Theo Felippe] Added configuration entries: `#default_request_format` and `default_response_format`
- [Rodrigo Panachi] Introduced `logger` configuration for applications, to be used like this: `Web::Logger.debug`
- [Ben Lovell] Simpler and less verbose RSpec tests
- [Pascal Betz] Introduced `--method` CLI argument for action generator as a way to specify the HTTP verb

### Fixed
- [Luca Guidi] Handle conflicts between directories with the same name while serving static assets
- [Derk-Jan Karrenbeld] Include default value `font-src: self` for CSP HTTP header
- [Cam Huynh] Make CLI arguments immutable for `Lotus::Environment`
- [Andrii Ponomarov] Disable welcome page in test environment
- [Alfonso Uceda Pompa] Print error message and exit when no name is provided to model generator

### Changed
- [Theo Felippe] Deprecated `#default_format` in favor of: `#default_request_format`

## v0.4.1 - 2015-07-10
### Added
- [Trung Lê] Alias `--database` as `--db` for `lotus new`

### Fixed
- [Alfonso Uceda Pompa] Ensure to load correctly apps in `lotus console`
- [Alfonso Uceda Pompa] Ensure to not duplicate prefix for Container mounted apps (eg `/admin/admin/dashboard`)
- [Alfonso Uceda Pompa] Ensure generator for "application" architecture to generate session secret
- [Alfonso Uceda Pompa & Trung Lê & Hiếu Nguyễn] Exit unsuccessfully when `lotus generate model` doesn't receive a mandatory name for model
- [Miguel Molina] Exit unsuccessfully when `lotus new --database` receives an unknown value
- [Luca Guidi] Ensure to prepend sessions middleware, so other Rack components can have access to HTTP session

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
- [Luca Guidi] New projects should depend on `lotus-model ~> 0.4`

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
- [Linus Pettersson] Allow to specify `--database` CLI option when generate a new project. Eg. `lotus new bookshelf --database=postgresql`
- [Linus Pettersson] Initialize a Git repository when generating a new project
- [Alfonso Uceda Pompa] Produce `.lotusrc` when generating a new project
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
- [Jimmy Zhang] Project generator for the current directory (`lotus new .`). This is useful to provide a web deliverable for existing Ruby gems.
- [Trung Lê] Add example mapping file for project generator: `lib/config/mapping.rb`
- [Hiếu Nguyễn] RSpec support for project generator: `--test=rspec` or `--test=minitest` (default)

### Fixed
- [Luca Guidi] `lotus version` to previx `v` (eg `v0.2.1`)
- [Rob Yurkowski] Ensure project name doesn't contain special or forbidden characters
- [Luca Guidi] Ensure all the applications are loaded in console
- [Trung Lê] Container architecture: preload only `lib/<projectname>/**/*.rb`
- [Hiếu Nguyễn] Fixed `lotus new` to print usage when project name isn't provided

## v0.2.0 - 2014-06-23
### Added
- [Luca Guidi] Introduced `lotus new` as a command to generate projects. It supports "container" architecture for now.
- [Luca Guidi] Show a welcome page when one mounted Lotus application doesn't have routes
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
