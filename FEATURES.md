# Lotus
### A complete web framework for Ruby

## Features

## v0.4.0 - 2015-06-23

- Application architecture
- Database migrations
- CLI: `lotus db` commands: `create`, `drop`, `prepare`, `migrate`, `version`, `apply`.
- HTML5 Form helpers
- Cross Site Request Forgery (CSRF) protection
- Force SSL
- Number formatting helper

## v0.3.2 - 2015-05-22

- Automatic secure cookies
- Routing helpers for actions
- Send files from actions
- `Lotus.root` returns top level directory of the project.

## v0.3.1 - 2015-05-15

- CLI: `lotus generate app admin` creates a new application (`apps/admin`).
- CLI: `lotus generate model user`. It generates entity, repository and related unit test files.
- `Lotus.env` and `Lotus.env?` for current environment introspection (eg. `Lotus.env?(:test)` or `Lotus.env?(:staging, :production)`)
- Allow repositories to execute raw query/commands against database
- Automatic timestamps update for entities
– Dirty Tracking for entities (via `Lotus::Entity::DirtyTracking`)
- Nested RESTful resource(s)
- String pluralization and singularization

## v0.3.0 - 2015-03-23

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

## v0.2.1 - 2015-02-06

- Allow entities to include validations.
- `lotus new .` to generate a Lotus application for an existing code base (Eg. a gem that needs a web UI).
- `lotus new` supports `--path` (for destination directory), `--test` (to generate Minitest or RSpec boilerplate).
- Lotus logger

## v0.2.0 - 2014-12-23

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

## v0.1.0 - 2014-06-23

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
