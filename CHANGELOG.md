# Hanami
The web, with simplicity.

## v2.0.0.alpha7.1 - 2020-03-09

## Fixed
- [Tim Riley] Fixed error creating slice classes when the enclosing module did not already exist

## v2.0.0.alpha7 - 2020-03-08

## Added
- [Tim Riley] Introduced `Hanami::ApplicationLoadError` and `Hanami::SliceLoadError` exceptions to represent errors encountered during application and slice loading.
- [Tim Riley] `Hanami::Slice.shutdown` can be used to stop all the providers in a slice

## Changed
- [Tim Riley] Slices are now represented as concrete classes (such as `Main::Slice`) inheriting from `Hanami::Slice`, as opposed to _instances_ of `Hanami::Slice`. You may create your own definitions for these slices in `config/slices/[slice_name].rb`, which you can then use for customising per-slice config and behavior, e.g.

    ```ruby
    # config/slices/main.rb:

    module Main
      class Slice < Hanami::Slice
        # slice config here
      end
    end
    ```
- [Tim Riley] Application-level `config.slice(slice_name, &block)` setting has been removed in favour of slice configuration within concrete slice class definitions
- [Tim Riley] You can configure your slice imports inside your slice classes, e.g.

    ```ruby
    # config/slices/main.rb:

    module Main
      class Slice < Hanami::Slice
        # Import all exported components from "search" slice
        import from: :search
      end
    end
    ```
- [Tim Riley] You can configure your slice exports inside your slice classes, e.g.

    ```ruby
    # config/slices/search.rb:

    module Search
      class Slice < Hanami::Slice
        # Export the "index_entity" component only
        export ["index_entity"]
      end
    end
    ```
- [Tim Riley] For advanced cases, you can configure your slice's container via a `prepare_container` block:

    ```ruby
    # config/slices/search.rb:

    module Search
      class Slice < Hanami::Slice
        prepare_container do |container|
          # `container` object is available here, with
          # slice-specific configuration already applied
        end
      end
    end
    ```
- [Tim Riley] `Hanami::Application.shutdown` will now also shutdown all registered slices

## v2.0.0.alpha6 - 2022-02-10
### Added
- [Luca Guidi] Official support for Ruby: MRI 3.1
- [Tim Riley] Introduce partial Slice imports and exports. It allows to selectively export a functionality from a slice and import into another.

    Import from `search` slice, uses `search` as the imported key namespace:

    ```ruby
    # config/application.rb

    module MyApp
      class Application < Hanami::Application
        config.slice(:admin) do
          import(from: :search)
        end
      end
    end
    ```

    Import from `search` slice with custom namespace:

    ```ruby
    # config/application.rb

    module MyApp
      class Application < Hanami::Application
        config.slice(:admin) do
          import(from: :search, as: :search_engine)
        end
      end
    end
    ```

    Import specific keys from `search` slice

    ```ruby
    # config/application.rb

    module MyApp
      class Application < Hanami::Application
        config.slice(:admin) do
          import(keys: ["run_query"], from: :search)
        end
      end
    end
    ```

    Export only specific keys from `search` slice, and import them in `admin`

    ```ruby
    # config/application.rb

    module MyApp
      class Application < Hanami::Application
        config.slice(:admin) do
          import(from: :search)
        end

        config.slice(:search) do
          container.config.exports = %w[run_query index_item]
        end
      end
    end
    ```

### Fixed
- [Luca Guidi] Ensure request logger to respect logger formatter option.

### Changed
- [Luca Guidi] Drop support for Ruby: MRI 2.6 and 2.7.
- [Tim Riley] `Hanami.init` => `Hanami.prepare` and `hanami/init` => `hanami/prepare`
- [Tim Riley] `Hanami.register_bootable` => `Hanami.register_provider`
- [Tim Riley] `Hanami.start_bootable` => `Hanami.start`
- [Tim Riley] `Hanami::Slice#init` => `Hanami::Slice#prepare`
- [Tim Riley] `Hanami::Slice#register_bootable` => `Hanami::Slice#register_provider`
- [Tim Riley] `Hanami::Slice#start_bootable` => `Hanami::Slice#start`

## v2.0.0.alpha5 - 2022-01-12
### Changed
- [Luca Guidi] Sensible default configuration for application logger, with per-environment defaults:

    The defaults are:

    - In **production**, log for level `info`, send logs to `$stdout` in JSON format without colours
    - In **development**, log for level `debug`, send logs to `$stdout` in single-line format with colours
    - In **test**, log for level `debug`, send logs to `log/test.log` in single-line format without colours

    To configure the logger:

    ```ruby
    module MyApp
      class Application < Hanami::Application
        config.logger.level = :info

        config.logger.stream = $stdout
        config.logger.stream = "/path/to/file"
        config.logger.stream = StringIO.new

        config.logger.format = :json
        config.logger.format = MyCustomFormatter.new

        config.logger.color = false # disable coloring
        config.logger.color = MyCustomColorizer.new

        config.logger.filters << "secret" # add
        config.logger.filters += ["yet", "another"] # add
        config.logger.filters = ["foo"] # replace

        # See https://ruby-doc.org/stdlib/libdoc/logger/rdoc/Logger.html
        config.logger.options = ["daily"] # time based log rotation
        config.logger.options = [0, 1048576] # size based log rotation
      end
    end
    ```

    To configure the logger for specific environments:

    ```ruby
    module MyApp
      class Application < Hanami::Application
        config.environment(:staging) do
          config.logger.level = :info
        end
      end
    end
    ```

    To assign a custom replacement logger object:

    ```ruby
    module MyApp
      class Application < Hanami::Application
        config.logger = MyCustomLogger.new
      end
    end
    ```
- [Tim Riley] Comprehensive `config.source_dirs` setting

    This replaces the previous `component_dir_paths` setting, and contains two nested settings:

    - `config.source_dirs.component_dirs` (backed by `Dry::System::Config::ComponentDirs`), for directories of source files intended to be registered as components
    - `config.source_dirs.autoload_paths`, for directories of source files not intended for registration as components, but still to be made accessible by the autoloader

    To add and configure your own additional component dirs:

    ```ruby
    module MyApp
      class Application < Hanami::Application
        # Adding a simple component dir
        config.source_dirs.component_dirs.add "serializers"

        # Adding a component dir with custom configuration
        config.source_dirs.component_dirs.add "serializers" do |dir|
          dir.auto_register = proc { |component|
            !component.identifier.start_with?("structs")
          }
        end
      end
    end
    ```

    To customize the configuration of the default component dirs ("lib", "actions", "repositories", "views"):

    ```ruby
    module MyApp
      class Application < Hanami::Application
        # Customising a default component dir
        config.source_dirs.component_dirs.dir("lib").auto_register = proc { |component|
          !component.identifier.start_with?("structs")
        }

        # Setting default config to apply to all component dirs
        config.source_dirs.component_dirs.auto_register = proc { |component|
          !component.identifier.start_with?("entities")
        }

        # Removing a default component dir
        config.source_dirs.component_dirs.delete("views")
      end
    end
    ```

    To configure the autoload paths (defaulting to `["entities"]`):

    ```ruby
    module MyApp
      class Application < Hanami::Application
        # Adding your own autoload paths
        config.source_dirs.autoload_paths << "structs"

        # Or providing a full replacement
        config.source_dirs.autoload_paths = ["structs"]
      end
    end
    ```
- [Tim Riley] Application router is lazy loaded (not requiring application to be fully booted) and now available via `Hanami.rack_app` or `Hanami.application.rack_app`, instead of the previous `Hanami.app` (which required the app to be booted first).

## v2.0.0.alpha4 - 2021-12-07
### Added
- [Luca Guidi] Manage Content Security Policy (CSP) with "zero-defaults" policy. New API to change CSP values and to disable the feature.
    ```ruby
    # Read a CSP value

    module MyApp
      class Application < Hanami::Application
        config.actions.content_security_policy[:base_uri] # => "'self'"
      end
    end
    ```

    ```ruby
    # Override a default CSP value

    module MyApp
      class Application < Hanami::Application
        # This line will generate the following CSP fragment
        # plugin-types ;
        config.actions.content_security_policy[:plugin_types] = nil
      end
    end
    ```

    ```ruby
    # Append to a default CSP value

    module MyApp
      class Application < Hanami::Application
        # This line will generate the following CSP fragment
        # script-src 'self' https://my.cdn.test;
        config.actions.content_security_policy[:script_src] += " https://my.cdn.test"
      end
    end
    ```

    ```ruby
    # Add a custom CSP key. Useful when CSP standard evolves.

    module MyApp
      class Application < Hanami::Application
        # This line will generate the following CSP fragment
        # my-custom-setting 'self';
        config.actions.content_security_policy[:my-custom-setting] = "'self'"
      end
    end
    ```

    ```ruby
    # Delete a CSP key.

    module MyApp
      class Application < Hanami::Application
        config.actions.content_security_policy.delete(:object_src)
      end
    end
    ```

    ```ruby
    # Disable CSP feature.

    module MyApp
      class Application < Hanami::Application
        config.actions.content_security_policy = false
      end
    end
    ```

## v2.0.0.alpha3 - 2021-11-09
### Added
- [Luca Guidi] Added `Hanami.shutdown` to stop all bootable components in the application container
- [Tim Riley] Added `component_dir_paths` application setting to allow for components to be loaded from additional directories inside each slice directory. To begin with, this defaults to `%w[actions repositories views]`. Components inside these directories are expected to be namespaced to match the directory name; e.g. given a `main` slice, `slices/main/actions/home.rb` is expected to define `Main::Actions::Home`, and will be registered in the slice container as `"actions.home"`.

### Changed
- [Tim Riley] A slice's classes can now be defined directly inside `slices/[slice_name]/lib/`; e.g. given a `main` slice, `slices/main/lib/example.rb` is expected to define `Main::Example`, and will be registered in the slice container as `"example"`
- [Tim Riley] The root `lib/` directory is no longer configured as a component dir, and classes inside `lib/[app_namespace]/` will no longer be auto-registered into the container. If you need to share components, create them in their own slices as appropriate, and import those slices into the other slices that require them.
- [Tim Riley] `lib/[app_namespace]/` is configured for autoloading, and `lib/` is added to `$LOAD_PATH` to support explicit requires for source files outside `lib/[app_namespace]/`.
- [Tim Riley] (Internal) Ported `Hanami::Configuration` and related classes to use dry-configurable
- [Tim Riley] Application inflector can be entirely replaced, if required, via `Hanami::Configuration#inflector=`. Custom inflection rules can still be provided to the default inflector via `Hanami::Configuration#inflections`.
- [Marc Busqué] App settings are defined within a concrete class rather than an anonymous block, to allow for users to leverage the typical behavior of Ruby classes, such as for defining their own types module to use for coercing setting values. This class also relies on dry-configurable for its settings implementation, so the standard dry-configurable `setting` API is available, such as the `constructor:` and `default:` options.
    ```ruby
    # frozen_string_literal: true

    require "dry/types"
    require "hanami/application/settings"

    module TestApp
      class Settings < Hanami::Application::Settings
        # Example usage of a types module (previously not possible inside the anonymous block)
        Types = Dry.Types()

        setting :session_secret, constructor: Types::String.constrained(min_size: 20)

        setting :some_bool, constructor: Types::Params::Bool, default: false
      end
    end
    ```
- [Marc Busqué] Application `settings_loader` and `settings_loader_options` have been replaced with `settings_store`, which is an updated abstraction for providing setting values to work with the new `Hanami::Application::Settings` implementation noted above (see `Application::Settings::DotenvStore` for the default store, which provides the same behavior as previously)
- [Marc Busqué] Routes are defined within a concrete class rather than an anonymous block, to provide consistency with the settings (noted above), as well a place for additional behavior (in future releases):
    ```ruby
    # frozen_string_literal: true

    require "hanami/application/routes"

    module MyApp
      class Routes < Hanami::Application::Routes
        define do
          slice :main, at: "/" do
            root to: "home.show"
          end
        end
      end
    end
    ```

## v2.0.0.alpha2 - 2021-05-04
### Added
- [Luca Guidi] Official support for Ruby: MRI 3.0
- [Tim Riley] Code autoloading via Zeitwerk
- [Tim Riley] `Hanami::Application` subclasses generate and configure a `Dry::System::Container`, accessible via `.container` and `AppNamespace::Container`, with several common container methods available directly via the application subclass (e.g. `Bookshelf::Application["foo"]` or `Hanami.application["foo"]`)
- [Tim Riley] Introduced `Hanami::Application.register_bootable` to register custom components
- [Tim Riley] Introduced `Hanami::Application.keys` to get the list of resolved components
- [Tim Riley] Dynamically create an auto-injection mixin (e.g. `Bookshelf::Deps`)
    ```ruby
    # frozen_string_literal: true

    module Bookshelf
      class CreateThing
        include Deps[service_client: "some_service.client"]

        def call(attrs)
          # Validate attrs, etc.
          service_client.create(attrs)
        end
      end
    end
    ```
- [Tim Riley] Introduced application settings. They are accessible via `Hanami.application.settings` in `config/settings.rb`
- [Tim Riley] Introduced application slices to organise high-level application concerns. Slices are generated based on subdirectories of `slices/`, and map onto corresponding ruby module namespaces, e.g. `slices/main` -> `Main`, with the slice instance itself being `Main::Slice` (as well as being accessible via `Hanami.application.slices[:main]`)
- [Tim Riley] Each slice generates and configures has its own `Dry::System::Container`, accessible via the slice instance (e.g. `Main::Slice.container`) as well as via its own constant (e.g. `Main::Container`)
- [Tim Riley] Slice containers automatically import the application container, under the `"application"` namespace
- [Tim Riley] Allow slice containers to be imported by other slice containers

### Changed
- [Luca Guidi] Drop support for Ruby: MRI 2.5
- [Tim Riley] Removed `config.cookies` in favor of `config.actions.cookies`
- [Tim Riley] Removed `config.sessions` in favor of `config.actions.sessions`
- [Tim Riley] Removed `config.security` settings

## v2.0.0.alpha1 - 2019-01-30
### Added
- [Luca Guidi] Implemented from scratch `hanami version`
- [Luca Guidi] Implemented from scratch `hanami server`
- [Luca Guidi] Main configuration is opinionated: when a setting is not specified in generated code, it uses a framework default.
- [Luca Guidi] Main configuration setting `environment`: to yield env based settings (e.g. `config.environment(:production) { |c| c.logger = {...} }`)
- [Luca Guidi] Main configuration setting `base_url`: to set the base URL of the app (e.g. `config.base_url = "https://example.com"`)
- [Luca Guidi] Main configuration setting `logger`: to set the logger options (e.g. `config.logger = { level: :info, format: :json }`)
- [Luca Guidi] Main configuration setting `routes`: to set the path to routes file (e.g. `config.routes = "path/to/routes"`)
- [Luca Guidi] Main configuration setting `cookies`: to set cookies options (e.g. `config.cookies = { max_age: 300 }`)
- [Luca Guidi] Main configuration setting `sessions`: to set session options (e.g. `config.sessions = :cookie, { secret: "abc" }`)
- [Luca Guidi] Main configuration setting `default_request_format`: to set the fallback for request format (aka MIME Type) (e.g. `config.default_request_format = :json`)
- [Luca Guidi] Main configuration setting `default_response_format`: to set the default response format (aka MIME Type) (e.g. `config.default_response_format = :json`)
- [Luca Guidi] Main configuration setting `middleware` to mount Rack middleware (e.g. `config.middleware.use MyMiddleware, "argument"`)
- [Luca Guidi] Main configuration setting `security` to set security settings (see below)
- [Luca Guidi] Main configuration setting `inflections` to configure inflections (e.g. `config.inflections { |i| i.plural "virus", "viruses" }`)
- [Luca Guidi] Main configuration security setting `x_frame_options`: defaults to `"deny"` (e.g. `config.security.x_frame_options = "sameorigin"`)
- [Luca Guidi] Main configuration security setting `x_content_type_options`: defaults to `"nosniff"` (e.g. `config.security.x_content_type_options = nil`)
- [Luca Guidi] Main configuration security setting `x_xss_protection`: defaults to `"1; mode=block"` (e.g. `config.security.x_xss_protection = "1"`)
- [Luca Guidi] Main configuration security setting `content_security_policy`: defaults to `"form-action 'self'; frame-ancestors 'self'; base-uri 'self'; default-src 'none'; script-src 'self'; connect-src 'self'; img-src 'self' https: data:; style-src 'self' 'unsafe-inline' https:; font-src 'self'; object-src 'none'; plugin-types application/pdf; child-src 'self'; frame-src 'self'; media-src 'self'"`
  (e.g. `config.security.content_security_policy[:style_src] += " https://my.cdn.example"` to add another source)
  (e.g. `config.security.content_security_policy[:plugin_types] = nil` to override the settings)

### Changed
- [Luca Guidi] Drop support for Ruby: MRI 2.3, and 2.4.
- [Luca Guidi] `Hanami::Application` must be used as superclass for main application under `config/application.rb` (e.g. `Bookshelf::Application`)
- [Luca Guidi] Main configuration is available at `config/application.rb` instead of `config/enviroment.rb`
- [Luca Guidi] Removed `Hanami.configure` in favor of main application configuration (e.g. `Bookshelf::Application.config`)
- [Luca Guidi] Removed DSL syntax for main configuration (from `cookies max_age: 600` to `config.cookies = { max_age: 600 }`)
- [Luca Guidi] Per enviroment settings must be wrapped in a block (e.g. `config.enviroment(:production) { |c| c.logger = {} }`)
- [Luca Guidi] Concrete applications are no longer supported (e.g. `Web::Application` in `apps/web/application.rb`)
- [Luca Guidi] Main routes must be configured at `config/routes.rb`:
```ruby
# frozen_string_literal: true

Hanami.application.routes do
  mount :web, at: "/" do
    root to: "home#index"
  end

  mount :admin, at: "/admin" do
    root to: "home#index"
  end
end
```
- [Luca Guidi] Per application routes are no longer supported (e.g. `apps/web/config/routes.rb`)
- [Luca Guidi] Removed `shotgun` and code reloading from the core. Code reloading is implemented by `hanami-reloader` gem.
- [Luca Guidi] Removed support for `.hanamirc`

## v1.3.4 - 2021-05-02
### Fixed
- [Slava Kardakov] Fix generated `config.ru` `require_relative` statement
- [Armin] Fix `Hanami::CommonLogger` elapsed time compatibility with `rack` 2.1.0+
- [Adam Daniels] Fix generated tests compatibility with `minitest` 6.0+

## v1.3.3 - 2019-09-20
### Added
- [Gray Manley] Standardize file loading for `.env` files (see: https://github.com/bkeepers/dotenv#what-other-env-files-can-i-use)

### Fixed
- [Alfonso Uceda & Luca Guidi] Ensure to use `:host` option when mounting an application in main router (e.g. `mount Beta::Application.new, at: "/", host: "beta.hanami.test"`)

## v1.3.2 - 2019-07-26
### Added
- [Luca Guidi] Support both `hanami-validations` 1 and 2

### Fixed
- [Wisnu Adi Nurcahyo] Ensure `hanami generate` syntax for Welcome page is compatible with ZSH
- [Luca Guidi] Don't let `hanami` to crash when called without `bundle exec`

## v1.3.1 - 2019-01-18
### Added
- [Luca Guidi] Official support for Ruby: MRI 2.6
- [Luca Guidi] Support `bundler` 2.0+

### Fixed
- [Aidan Coyle] Remove from app generator support for deprecated `force_ssl` setting
- [Alessandro Caporrini] Remove from app generator support for deprecated `body_parsers` setting
- [Daphne Rouw & Sean Collins] Make app generator to work when code in `config/environment.rb` uses double quotes

## v1.3.0 - 2018-10-24
### Added
- [Luca Guidi] Automatically log body payload from body parsers

### Fixed
- [Luca Guidi] Generate correct syntax for layout unit tests
- [Vladislav Yashin] Fix concatenation of `Pathname` and `String` in `Hanami::CommonLogger`

## v1.3.0.beta1 - 2018-08-08
### Added
- [Sean Collins] Generate new projects with RSpec as default testing framework
- [Alfonso Uceda] Generate actions/views/mailers with nested module/class definition

### Fixed
- [Anton Davydov] Make possible to pass extra settings for custom logger instances (eg. `logger SemanticLogger.new, :foo, :bar`)
- [graywolf] Ensure `hanami generate app` to work without `require_relative` entries in `config/environment.rb`
- [Makoto Tajitsu & Luca Guidi] Fixed regression for `hanami new .` that used to generate a broken project

### Fixed
- [John Downey] Don't use thread unsafe `Dir.chdir` to serve static assets

## v1.2.0 - 2018-04-11

## v1.2.0.rc2 - 2018-04-06
### Fixed
- [Kelsey Judson] Ensure to not reload code under `lib/` when `shotgun` isn't bundled

## v1.2.0.rc1 - 2018-03-30

## v1.2.0.beta2 - 2018-03-23
### Fixed
- [Luca Guidi] Raise meaningful error message when trying to access `session` or `flash` with disabled sessions
- [Pistos] Print stack trace to standard output when a CLI command raises an error

## v1.2.0.beta1 - 2018-02-28
### Added
- [Luca Guidi] HTTP/2 Early Hints

### Fixed
- [Alfonso Uceda] Render custom template if an exception is raised from a view or template

## v1.1.1 - 2018-02-27
### Added
- [Luca Guidi] Official support for Ruby MRI 2.5+

### Fixed
- [Alfonso Uceda] Fixed regression for mailer generator: when using options like `--from` and `--to` the generated Ruby code isn't valid as it was missing string quotes.
- [Luca Guidi] Generate tests for views including `:format` in `exposures`. This fixes view unit tests when the associated template renders a partial.

## v1.1.0 - 2017-10-25
### Fixed
- [Luca Guidi] Ensure `hanami db rollback` steps to be a positive integer

## v1.1.0.rc1 - 2017-10-16
### Added
- [Yuji Ueki] Generate RSpec tests with `:type` metadata (eg `type: :action`)
- [Kirill] Add `--relation` option for `hanami generate model` (eg `bundle exec hanami generate model user --relation=accounts`)

## v1.1.0.beta3 - 2017-10-04
### Fixed
- [Luca Guidi] Don't require `:plugins` group when running `hanami new`

## v1.1.0.beta2 - 2017-10-03
### Added
- [Luca Guidi] Introduce `:plugins` group for `Gemfile` in order enable Hanami plugin gems
- [Alfonso Uceda] CLI: `hanami db rollback` to revert one or more migrations at once

### Fixed
- [Gabriel Gizotti] Fix generate/destroy for nested actions

## v1.1.0.beta1 - 2017-08-11
### Added
- [Ben Johnson] Allow to use custom logger as `Hanami.logger` (eg. `Hanami.configure { logger Timber::Logger.new($stdout) }`)
- [akhramov] Generate spec file for application layout when generating a new app
- [Anton Davydov] Generate `README.md` file for new projects
- [Anton Davydov] Selectively boot apps via `HANAMI_APPS=web bundle exec hanami server`
- [Marion Duprey & Gabriel Gizotti] Log payload (params) for non-GET HTTP requests
- [Marion Duprey & Gabriel Gizotti] Filter sensitive data in logs

### Fixed
- [jarosluv] Ensure to remove the correct migration file when executing `hanami db destroy model`
- [sovetnik] Fix require path for Minitest spec helper

## v1.0.0 - 2017-04-06

## v1.0.0.rc1 - 2017-03-31
### Added
- [Luca Guidi] Allow `logger` setting in `config/environment.rb` to accept arbitrary arguments to make `Hanami::Logger` to be compatible with Ruby's `Logger`. (eg. `logger 'daily', level: :info`)

### Fixed
- [Luca Guidi] Ensure code reloading don't misconfigure mailer settings (regression from v1.0.0.beta3)
- [Luca Guidi] Ensure database disconnection to happen in the same thread of `Hanami.boot`
- [Luca Guidi] Ensure `mailer` block in `config/environment.rb` to be evaluated multiple times, according to the current Hanami environment
- [Luca Guidi] Ensure a Hanami project to require only once the code under `lib/`

## v1.0.0.beta3 - 2017-03-17
### Fixed
- [Luca Guidi] Try to disconnect from database at the boot time. This is useful to prune stale connection during production deploys.
- [Tobias Sandelius] Don't mount `Hanami::CommonLogger` middleware if logging is disabled for the project.
- [Anton Davydov] Don't configure mailers, if it's mailing is disabled for the project.
- [Marcello Rocha] Ensure code reloading don't misconfigure mailer settings
- [Jimmy Börjesson] Make `apps/web/application.rb` code to wrap around the 80th column

### Changed
- [Luca Guidi] Removed deprecated `ApplicationConfiguration#default_format`. Use `#default_request_format` instead.

## v1.0.0.beta2 - 2017-03-02

## v1.0.0.beta1 - 2017-02-14
### Added
- [Luca Guidi] Official support for Ruby: MRI 2.4
- [yjukaku] CLI: `hanami generate model` now also generates a migration
- [Luca Guidi] Generate `config/boot.rb` for new Hanami projects.
- [Luca Guidi] Introduced `Hanami.logger` as project logger
- [Luca Guidi] Automatic logging of HTTP requests, migrations, and SQL queries
- [Luca Guidi] Introduced `environment` for env specific settings in `config/environment.rb`

### Fixed
- [Marcello Rocha] Fix Hanami::Mailer loading
- [Kai Kuchenbecker] Serve only existing assets with `Hanami::Static`
- [Gabriel Gizotti] Ensure inline ENV vars to not be overwritten by `.env.*` files
- [Adrian Madrid] Ensure new Hanami projects to have the right `jdbc` prefix for JRuby
- [Luca Guidi] Fixed code reloading for objects under `lib/`
- [Semyon Pupkov] Ensure generated mailer to respect the project name under `lib/`
- [Semyon Pupkov] Fixed generation of mailer settings for new projects
- [Victor Franco] Fixed CLI subcommands help output

### Changed
- [Ozawa Sakuro] Don't include `bundler` as a dependency `Gemfile` for new Hanami projects
- [Luca Guidi] Make compatible with Rack 2.0 only
- [Luca Guidi] Removed `logger` settings from Hanami applications
- [Luca Guidi] Removed logger for Hanami applications (eg `Web.logger`)
- [Luca Guidi] Changed mailer syntax in `config/environment.rb`

## v0.9.2 - 2016-12-19
## Added
- [The Crab] Mark unit tests/specs as pending for generated actions and views

### Fixed
- [Luca Guidi] Rake task `:environment` no longer depends on the removed `:preload` task
- [Luca Guidi] Ensure force SSL to use the default port, or the configured one
- [Luca Guidi] Boot the project when other it's started without `hanami server` (eg. `puma` or `rackup`)

## v0.9.1 - 2016-11-18
### Fixed
- [Luca Guidi] Ensure JSON body parser to not eval untrusted input

## v0.9.0 - 2016-11-15
### Added
- [Christophe Philemotte] Introduced `hanami secret` to generate and print a new sessions secret

### Fixed
- [Bruz Marzolf] Skip project code preloading when code reloading is enabled
- [Bruz Marzolf] Ensure to generate project in current directory when running `hanami new .`
- [Pascal Betz] Fix constant lookup within the project namespace
- [Sean Collins] Ensure consistent order of code loading across operating systems
- [Luca Guidi] Ensure to load the project configurations only once
- [Luca Guidi] Fix duplicated Rack middleware in single Hanami application stacks

### Changed
- [Luca Guidi] Official support for Ruby MRI 2.3+
- [Luca Guidi] Removed support for "application" architecture
- [Luca Guidi] Removed `Hanami::Container.new` in favor of `Hanami.app`
- [Luca Guidi] Removed `Hanami::Container.configure` in favor of `Hanami.configure`
- [Luca Guidi] Configure model and mailer within `Hanami.configure` block in `config/environment.rb`
- [Luca Guidi] Removed `mapping` from model configuration
- [Luca Guidi] Removed `Hanami::Application.preload!` in favor of `Hanami.boot`
- [Luca Guidi] Removed experimental code support for `entr(1)`
- [Luca Guidi & Sean Collins] Renamed assets configuration `digest` into `fingerprint`

## v0.8.0 - 2016-07-22
### Added
- [Luca Guidi] Generate new projects with Subresurce Integrity enabled in production (security).
- [Luca Guidi] Include `X-XSS-Protection: 1; mode=block` in default response headers (security).
- [Luca Guidi] Include `X-Content-Type-Options: nosniff` in default response headers (security).
- [Trung Lê & Neil Matatall] Added support for Content Security Policy 1.1 and 2.0
- [Andrey Deryabin] Experimental code reloading with `entr(1)`
- [Anton Davydov] Introduced JSON logging formatter for production environment
- [Anton Davydov] Allow to set logging formatters per app and per environment
- [Anton Davydov] Allow to set logging levels per app and per environment
- [Anton Davydov] Application logging now can log to any stream: standard out, file, `IO` and `StringIO` objects.
- [Andrey Deryabin] Allow new projects to be generated with `--template` CLI argument (eg. `hanami new bookshelf --template=haml`)
- [Sean Collins] Add `--version` and `-v` for `hanami version` CLI

### Fixed
- [Josh Bodah] Ensure consistent CLI messages
- [Andrey Morskov] Ensure consistent user experience and messages for generators
- [Luca Guidi] Fixed generators for camel case project names
- [Anton Davydov] Fixed model generator for camel case project names
- [Leonardo Saraiva] Fix `Rakefile` generation to safely ignore missing RSpec in production
- [Sean Collins] When generate an action, append routes to route file (instead of prepend)
- [Sean Collins] When an action is destroyed via CLI, ensure to remove the corresponding route
- [Bernardo Farah] Fix `require_relative` paths for nested generated actions and views unit tests
- [Anton Davydov] If database and assets Rake tasks fails, ensure to exit the process with a non-successful code
- [Luca Guidi] remove `Shotgun::Static` in favor of `Hanami::Assets::Static` for development/test and `Hanami::Static` for production
- [Alexandr Subbotin] Load initializers in alphabetical order
- [Matt McFarland] Fix server side error when CSRF token is not sent
- [Erol Fornoles] Fix route generations for mounted apps
- [Mahesh] Fix destroy action for application architecture
- [Karim Tarek & akhramov] Reference rendering errors in Rack env's `rack.exception` variable. This enables compatibility with exception reporting SaaS.
- [Luca Guidi] Detect assets dependencies changes in development (Sass/SCSS)
- [Luca Guidi & Lucas Amorim] Make model generator not dependendent on the current directory name, but to the project name stored in `.hanamirc`

### Changed
– [Luca Guidi] Drop support for Ruby 2.0 and 2.1
- [Trung Lê] Database env var is now `DATABASE_URL` (without the project name prefix like `BOOKSHELF_DATABASE_URL`
- [Trung Lê] `lib/config/mapping.rb` is no longer generated for new projects and no longer loaded.
- [Anton Davydov] New generated projects will depend (in their `Gemfile`) on `hanami` tiny version (`~> 0.8'`) instead of patch version (`0.8.0`)
- [Andrey Deryabin] `dotenv` is now a soft dependency that will be added to the `Gemfile` `:development` and `:test` groups for new generated projects.
- [Andrey Deryabin] `shotgun` is now a soft dependency that will be added to the `Gemfile` `:development` group for new generated projects.
- [Anton Davydov] New logo in welcome page
- [Ozawa Sakuro] Remove `require 'rubygems'` from generated code (projects, apps, routes, etc..)
- [Eric Freese] Disable Ruby warnings in generated `Rakefile` for Minitest/RSpec tasks
- [Luca Guidi] Allow views to render any HTTP status code. In actions use `halt(422)` for default status page or `self.status = 422` for view rendering.

## v0.7.3 - 2016-05-23
### Fixed
- [Pascal Betz] Use `Shotgun::Static` to serve static files in development mode and avoid to reload the env

## v0.7.2 - 2016-02-09
### Fixed
- [Alfonso Uceda Pompa] Fixed routing issue when static assets server tried to hijack paths that are matching directories in public directory

## v0.7.1 - 2016-02-05
### Fixed
- [Anton Davydov] Fixed routing issue when static assets server tried to hijack requests belonging to dynamic endpoints
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
- [Alfonso Uceda Pompa] Allow to specify default cookies options in application configuration. Eg. `cookies true, { domain: 'lotusrb.org' }`
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
