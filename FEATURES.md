# Hanami
### The web, with simplicity.

## Features

## v1.2.0 - 2018-04-11

- HTTP/2 Early Hints
- Unobtrusive JavaScript (UJS) (via `hanami-ujs` gem)
- Interactive console for development error page (via `hanami-webconsole` gem)
- CLI: register callbacks for `hanami` commands (`Hanami::CLI.after("db migrate", MyCallback.new)` or `Hanami::CLI.after("db migrate") { ... }`)
- Project level Rack middleware stack (`Hanami.configure { middleware.use MyRackMiddlewre }`)
- Plugins can hook into project configuration (`Hanami.plugin { middleware.use AnotherRackMiddleware }`)
- Custom repository commands
- Coloured logging

## v1.1.1 - 2018-02-27

## v1.1.0 - 2017-10-25

- One-To-Many association (aka `belongs_to`)
- One-To-One association (aka `has_one`)
- Many-To-Many association (aka `has_many :through`)
- Allow third-party developers to register commands for CLI (eg `hanami generate webpack`)
- Initial support for plugins via `:plugins` group in `Gemfile`
- CLI: `hanami db rollback` to rollback database migrations
- Introduced new extra behaviors for entity manual schema: `:schema` (default), `:strict`, `:weak`, and `:permissive`
- Custom logger for `Hanami.logger`
- Selectively boot apps via `HANAMI_APPS=web` env var
- Log payload (params) for non-GET HTTP requests
- Filter sensitive data in logs

### v1.0.0 - 2017-04-06

- Logger rotation
- Added: `Action#unsafe_send_file` to send files outside of the public directory
- CLI: `hanami generate model` now also generates a migration
- Project logger `Hanami.logger`
- Automatic logging of HTTP requests, migrations, and SQL queries

### v0.9.2 - 2016-12-19

### v0.9.1 - 2016-11-18

### v0.9.0 - 2016-11-15

- Experimental repositories associations (only "has many")
- Database automapping for SQL databases
- Entities schema
- Immutable entities
- Removed dirty tracking for entities
- Repositories CRUD operations can accept both entities and/or data
- Removed Memory and File System adapters
- SQLite is the default adapter for new projects
- Native support for PostgreSQL types
- CLI: `hanami secret` to generate and print a new session secret for a single Hanami app

### v0.8.0 - 2016-07-22

- New validation syntax based on predicates
- Custom and shared predicates for validations
- High level rules for validations
- Validations error messages with I18n support (via optional `i18n` gem)
- Mount applications in subdomains
- Added support for Content Security Policy 1.1 and 2.0
- Subresurce Integrity
- Include `X-Content-Type-Options` and `X-XSS-Protection` in default response headers
- Support for several JSON engines (via optional `multi_json` gem)
- JSON Logging for production
- Per environment logging levels, stream (file, stdout), formatters
- Introduced `#local` for views, layouts and templates to safely access locals by avoiding `nil` values
- Added `datalist` form helper
- CC and BCC support for mailers
- Experimental code reloading via `entr(1)`
- CLI: `hanami new` can be used with `--template` argument to generate a new project with (`erb`/`haml`/`slim`) templates

### v0.7.3 - 2016-05-23

### v0.7.2 - 2016-02-09

### v0.7.1 - 2016-02-05

### v0.7.0 - 2016-01-22

- Renamed from Lotus to Hanami

### v0.6.1 - 2016-01-19

### v0.6.0 - 2016-01-12

- Assets preprocessors support (eg. Sass, ES6, Opal, Less, CoffeScript..)
- Assets compressors (eg. YUI, UglifyJS2, Google Closure Compiler, Sass..)
- Assets helpers:
  * `javascript`
  * `stylesheet`
  * `favicon`
  * `image`
  * `video`
  * `audio`
  * `asset_path`
  * `asset_url`
- Content Delivery Network (CDN) support for static assets (CDN mode)
- Checksum suffix for static assets in production mode (Digest mode)
- Support for third party gems as assets distribution channel (eg. `lotus-jquery`)
- CLI: `lotus assets` command `precompile`: preprocess, minify and append checksum suffix
- CLI: `lotus destroy` destroy apps, models, actions, migrations and mailers
- Custom initializers (`apps/web/config/initializers`)
- Rake tasks `:preload` and `:environment`

### v0.5.0 - 2015-09-30

- Mailers
- CLI: `lotus generate mailer`
- SQL joins
- Custom coercers for data mapper

### v0.4.1 - 2015-07-10

### v0.4.0 - 2015-06-23

- Application architecture
- Database migrations
- CLI: `lotus db` commands: `create`, `drop`, `prepare`, `migrate`, `version`, `apply`.
- HTML5 Form helpers
- Cross Site Request Forgery (CSRF) protection
- Force SSL
- Number formatting helper

### v0.3.2 - 2015-05-22

- Automatic secure cookies
- Routing helpers for actions
- Send files from actions
- `Lotus.root` returns top level directory of the project.

### v0.3.1 - 2015-05-15

- CLI: `lotus generate app admin` creates a new application (`apps/admin`).
- CLI: `lotus generate model user`. It generates entity, repository and related unit test files.
- `Lotus.env` and `Lotus.env?` for current environment introspection (eg. `Lotus.env?(:test)` or `Lotus.env?(:staging, :production)`)
- Allow repositories to execute raw query/commands against database
- Automatic timestamps update for entities
– Dirty Tracking for entities (via `Lotus::Entity::DirtyTracking`)
- Nested RESTful resource(s)
- String pluralization and singularization

### v0.3.0 - 2015-03-23

- CLI: `lotus generate action web dashboard#index`. It generates an action, a view, a template, a route and related unit test files.
- CLI: `lotus db console`. It starts a database REPL.
- Full featured HTML5 markup generator for views (Eg. `html.div { p "Hello World" }`)
- Routing helpers in views and templates (Eg. `routes.home_path`).
- `lotus new` supports `--database` (Eg. `lotus new bookshelf --database=postgresql`).
- Initialize a Git repository when generate a new application
- Security: XSS (Cross Site Scripting) protections
- Security: Clickhijacking protection
- Security: Cookies are set as `HttpOnly` by default.
- Security: enable by default `X-Frame-Options` and `Content-Security-Policy` HTTP headers for new generated applications.
- Security: auto-escape output of presenters.
- Security: auto-escape output of virtual an concrete view methods.
- Security: view and template helpers for HTML, HTML attributes and URL escape. It's based on OWASP/ESAPI recommendations.
- Access nested action params with a safe API (`params.get('address.city')`).
- Interactors (aka Service Objects)
- Database transactions

### v0.2.1 - 2015-02-06

- Allow entities to include validations.
- `lotus new .` to generate a Lotus project for an existing code base (Eg. a gem that needs a web UI).
- `lotus new` supports `--path` (for destination directory), `--test` (to generate Minitest or RSpec boilerplate).
- Lotus logger

### v0.2.0 - 2014-12-23

- Support Minitest as default testing framework (`bundle exec rake` runs the entire test suite of an application).
- Support for _Method Override_ technique.
- Custom templates for non successful responses (Eg. `404.html.erb`).
- Support distinct `.env` files for each Lotus environment.
- Allow to configure multiple applications and handle Lotus environments accordingly.
- Allow to configure middleware stack, routes, database mapping and adapter for each application.
- Show a welcome page with instructions for new generated apps.
- CLI: `lotus routes`. It prints all the routes available for all the applications.
- CLI: `lotus new`. It generates a new application which can run multiple Lotus applications (_Container_ architecture).
- CLI: `lotus console`. It starts a Ruby REPL. It supports IRB (default), Pry and Ripl.
- CLI: `lotus server`. It starts a web server that supports code reloading. It supports all the Rack web servers (default: WEBRick).
- Database adapters: File system (default for new apps)
- Allow to share code for all the views and actions of an application
- Reusable validations framework (mixin). It supports: coercions and presence, format, acceptance, size, inclusion, exclusion, confirmation validations.
- Default Content-Type and Charset for responses
- Whitelist accepted MIME Types
- Custom exception handlers for actions
- Unique identifier for incoming HTTP requests
- Nested action params
- Action params _indifferent access_, whitelisting, validations and coercions
- HTTP caching (`Cache-Control`, `Last-Modified`, ETAG, Conditional GET, expires)
- JSON body parser for non-GET HTTP requests
- Routes inspector for CLI

### v0.1.0 - 2014-06-23

- Run multiple Lotus applications in the same Ruby process
- Serve static files
- Render default pages for non successful responses (404, 500, etc.)
- Support multiple Lotus environments (development, test and production)
- Full stack applications
- Data mapper
- Database adapters: Memory and SQL
- Reusable scopes for repositories
- Repositories
- Entities
- Custom rendering implementation via `#render` override in views
- Render partials and templates
- Presenters
- Layouts
- Views are able to handle multiple MIME Types according to the defined templates
- Support for all the most common template engines for Ruby. Including ERb, Slim, HAML, etc.
- Basic view rendering with templates
- Bypass rendering by setting a response body in actions (`self.body = "Hello"`)
- Single actions are able to mount Rack middleware
- Automatic MIME Type handling for request and responses
- HTTP sessions
- HTTP cookies
- HTTP redirect
- Action before/after callbacks
- Handle exceptions with HTTP statuses
- Action exposures, to expose a payload to pass to the other application layers
- Actions compatible with Rack
- Mount Rack applications
- Nested route namespaces
- RESTful resource(s), including collection and member actions
- Named routes, routes constraints, variables, catch-all
- Compatibility with Lotus::Controller
- HTTP redirect from the router
- HTTP routing compatible with Rack
- Thread safety
