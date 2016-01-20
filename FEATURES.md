# Hanami
### A complete web framework for Ruby

## Features

## v0.6.1 - 2016-01-19

## v0.6.0 - 2016-01-12

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
- Support for third party gems as assets distribution channel (eg. `hanami-jquery`)
- CLI: `hanami assets` command `precompile`: preprocess, minify and append checksum suffix
- CLI: `hanami destroy` destroy apps, models, actions, migrations and mailers
- Custom initializers (`apps/web/config/initializers`)
- Rake tasks `:preload` and `:environment`

## v0.5.0 - 2015-09-30

- Mailers
- CLI: `hanami generate mailer`
- SQL joins
- Custom coercers for data mapper

## v0.4.1 - 2015-07-10

## v0.4.0 - 2015-06-23

- Application architecture
- Database migrations
- CLI: `hanami db` commands: `create`, `drop`, `prepare`, `migrate`, `version`, `apply`.
- HTML5 Form helpers
- Cross Site Request Forgery (CSRF) protection
- Force SSL
- Number formatting helper

## v0.3.2 - 2015-05-22

- Automatic secure cookies
- Routing helpers for actions
- Send files from actions
- `Hanami.root` returns top level directory of the project.

## v0.3.1 - 2015-05-15

- CLI: `hanami generate app admin` creates a new application (`apps/admin`).
- CLI: `hanami generate model user`. It generates entity, repository and related unit test files.
- `Hanami.env` and `Hanami.env?` for current environment introspection (eg. `Hanami.env?(:test)` or `Hanami.env?(:staging, :production)`)
- Allow repositories to execute raw query/commands against database
- Automatic timestamps update for entities
– Dirty Tracking for entities (via `Hanami::Entity::DirtyTracking`)
- Nested RESTful resource(s)
- String pluralization and singularization

## v0.3.0 - 2015-03-23

- CLI: `hanami generate action web dashboard#index`. It generates an action, a view, a template, a route and related unit test files.
- CLI: `hanami db console`. It starts a database REPL.
- Full featured HTML5 markup generator for views (Eg. `html.div { p "Hello World" }`)
- Routing helpers in views and templates (Eg. `routes.home_path`).
- `hanami new` supports `--database` (Eg. `hanami new bookshelf --database=postgresql`).
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

## v0.2.1 - 2015-02-06

- Allow entities to include validations.
- `hanami new .` to generate a Hanami application for an existing code base (Eg. a gem that needs a web UI).
- `hanami new` supports `--path` (for destination directory), `--test` (to generate Minitest or RSpec boilerplate).
- Hanami logger

## v0.2.0 - 2014-12-23

- Support Minitest as default testing framework (`bundle exec rake` runs the entire test suite of an application).
- Support for _Method Override_ technique.
- Custom templates for non successful responses (Eg. `404.html.erb`).
- Support distinct `.env` files for each Hanami environment.
- Allow to configure multiple applications and handle Hanami environments accordingly.
- Allow to configure middleware stack, routes, database mapping and adapter for each application.
- Show a welcome page with instructions for new generated apps.
- CLI: `hanami routes`. It prints all the routes available for all the applications.
- CLI: `hanami new`. It generates a new application which can run multiple Hanami applications (_Container_ architecture).
- CLI: `hanami console`. It starts a Ruby REPL. It supports IRB (default), Pry and Ripl.
- CLI: `hanami server`. It starts a web server that supports code reloading. It supports all the Rack web servers (default: WEBRick).
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

## v0.1.0 - 2014-06-23

- Run multiple Hanami applications in the same Ruby process
- Serve static files
- Render default pages for non successful responses (404, 500, etc.)
- Support multiple Hanami environments (development, test and production)
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
- Compatibility with Hanami::Controller
- HTTP redirect from the router
- HTTP routing compatible with Rack
- Thread safety
