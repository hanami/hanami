RSpec.describe 'hanami new', type: :integration do
  it 'generates vanilla project' do
    project = 'bookshelf'
    output  = <<-OUT
      create  .hanamirc
      create  .env.development
      create  .env.test
      create  README.md
      create  Gemfile
      create  config.ru
      create  config/boot.rb
      create  config/environment.rb
      create  lib/#{project}.rb
      create  public/.gitkeep
      create  config/initializers/.gitkeep
      create  lib/#{project}/entities/.gitkeep
      create  lib/#{project}/repositories/.gitkeep
      create  lib/#{project}/mailers/.gitkeep
      create  lib/#{project}/mailers/templates/.gitkeep
      create  spec/#{project}/entities/.gitkeep
      create  spec/#{project}/repositories/.gitkeep
      create  spec/#{project}/mailers/.gitkeep
      create  spec/support/.gitkeep
      create  db/migrations/.gitkeep
      create  Rakefile
      create  .rspec
      create  spec/spec_helper.rb
      create  spec/features_helper.rb
      create  spec/support/capybara.rb
      create  db/schema.sql
      create  .gitignore
         run  git init . from "."
      create  apps/web/application.rb
      create  apps/web/config/routes.rb
      create  apps/web/views/application_layout.rb
      create  apps/web/templates/application.html.erb
      create  apps/web/assets/favicon.ico
      create  apps/web/controllers/.gitkeep
      create  apps/web/assets/images/.gitkeep
      create  apps/web/assets/javascripts/.gitkeep
      create  apps/web/assets/stylesheets/.gitkeep
      create  spec/web/features/.gitkeep
      create  spec/web/controllers/.gitkeep
      create  spec/web/views/application_layout_spec.rb
      insert  config/environment.rb
      insert  config/environment.rb
      append  .env.development
      append  .env.test
OUT

    run_command "hanami new #{project}", output

    within_project_directory(project) do
      # Assert it's an initialized Git repository
      run_command "git status", "On branch master"

      #
      # .hanamirc
      #
      expect('.hanamirc').to have_file_content <<-END
project=#{project}
test=rspec
template=erb
END

      #
      # .env.development
      #
      expect('.env.development').to have_file_content(%r{# Define ENV variables for development environment})
      expect('.env.development').to have_file_content(%r{DATABASE_URL="sqlite://db/#{project}_development.sqlite"})
      expect('.env.development').to have_file_content(%r{SERVE_STATIC_ASSETS="true"})
      expect('.env.development').to have_file_content(%r{WEB_SESSIONS_SECRET="[\w]{64}"})

      #
      # .env.test
      #
      expect('.env.test').to have_file_content(%r{# Define ENV variables for test environment})
      expect('.env.test').to have_file_content(%r{DATABASE_URL="sqlite://db/#{project}_test.sqlite"})
      expect('.env.test').to have_file_content(%r{SERVE_STATIC_ASSETS="true"})
      expect('.env.test').to have_file_content(%r{WEB_SESSIONS_SECRET="[\w]{64}"})

      #
      # README.md
      #
      expect('README.md').to have_file_content <<-END
# Bookshelf

Welcome to your new Hanami project!

## Setup

How to run tests:

```
% bundle exec rake
```

How to run the development console:

```
% bundle exec hanami console
```

How to run the development server:

```
% bundle exec hanami server
```

How to prepare (create and migrate) DB for `development` and `test` environments:

```
% bundle exec hanami db prepare

% HANAMI_ENV=test bundle exec hanami db prepare
```

Explore Hanami [guides](https://guides.hanamirb.org/), [API docs](http://docs.hanamirb.org/#{Hanami::VERSION}/), or jump in [chat](http://chat.hanamirb.org) for help. Enjoy! 🌸
END

      #
      # Gemfile
      #
      if Platform.match?(engine: :ruby)
        expect('Gemfile').to have_file_content <<-END
source 'https://rubygems.org'

gem 'rake'
gem 'hanami',       '#{Hanami::Version.gem_requirement}'
gem 'hanami-model', '~> 1.3'

gem 'sqlite3'

group :development do
  # Code reloading
  # See: https://guides.hanamirb.org/projects/code-reloading
  gem 'shotgun', platforms: :ruby
  gem 'hanami-webconsole'
end

group :test, :development do
  gem 'dotenv', '~> 2.4'
end

group :test do
  gem 'rspec'
  gem 'capybara'
end

group :production do
  # gem 'puma'
end
END
      end

      if Platform.match?(engine: :jruby)
        expect('Gemfile').to have_file_content <<-END
source 'https://rubygems.org'

gem 'rake'
gem 'hanami',       '#{Hanami::Version.gem_requirement}'
gem 'hanami-model', '~> 1.3'

gem 'jdbc-sqlite3'

group :test, :development do
  gem 'dotenv', '~> 2.4'
end

group :test do
  gem 'rspec'
  gem 'capybara'
end

group :production do
  # gem 'puma'
end
END
      end

      #
      # config.ru
      #
      expect('config.ru').to have_file_content <<-END
require './config/environment'

run Hanami.app
END

      #
      # config/boot.rb
      #
      expect('config/boot.rb').to have_file_content <<-END
require_relative './environment'
Hanami.boot
END

      #
      # config/environment.rb
      #
      expect('config/environment.rb').to have_file_content <<-END
require 'bundler/setup'
require 'hanami/setup'
require 'hanami/model'
require_relative '../lib/#{project}'
require_relative '../apps/web/application'

Hanami.configure do
  mount Web::Application, at: '/'

  model do
    ##
    # Database adapter
    #
    # Available options:
    #
    #  * SQL adapter
    #    adapter :sql, 'sqlite://db/#{project}_development.sqlite3'
    #    adapter :sql, 'postgresql://localhost/#{project}_development'
    #    adapter :sql, 'mysql://localhost/#{project}_development'
    #
    adapter :sql, ENV.fetch('DATABASE_URL')

    ##
    # Migrations
    #
    migrations 'db/migrations'
    schema     'db/schema.sql'
  end

  mailer do
    root 'lib/#{project}/mailers'

    # See https://guides.hanamirb.org/mailers/delivery
    delivery :test
  end

  environment :development do
    # See: https://guides.hanamirb.org/projects/logging
    logger level: :debug
  end

  environment :production do
    logger level: :info, formatter: :json, filter: []

    mailer do
      delivery :smtp, address: ENV.fetch('SMTP_HOST'), port: ENV.fetch('SMTP_PORT')
    end
  end
end
END

      project_module = Hanami::Utils::String.new(project).classify
      #
      # lib/<project>.rb
      #
      expect("lib/#{project}.rb").to have_file_content <<-END
module #{project_module}
end
END

      #
      # public/.gitkeep
      #
      expect('public/.gitkeep').to be_an_existing_file

      #
      # config/initializers/.gitkeep
      #
      expect('config/initializers/.gitkeep').to be_an_existing_file

      #
      # lib/<project>/entities/.gitkeep
      #
      expect("lib/#{project}/entities/.gitkeep").to be_an_existing_file

      #
      # lib/<project>/mailers/.gitkeep
      #
      expect("lib/#{project}/mailers/.gitkeep").to be_an_existing_file

      #
      # lib/<project>/mailers/templates/.gitkeep
      #
      expect("lib/#{project}/mailers/templates/.gitkeep").to be_an_existing_file

      #
      # spec/<project>/entities/.gitkeep
      #
      expect("spec/#{project}/entities/.gitkeep").to be_an_existing_file

      #
      # spec/<project>/repositories/.gitkeep
      #
      expect("spec/#{project}/repositories/.gitkeep").to be_an_existing_file

      #
      # spec/<project>/mailers/.gitkeep
      #
      expect("spec/#{project}/mailers/.gitkeep").to be_an_existing_file

      #
      # spec/support/.gitkeep
      #
      expect("spec/support/.gitkeep").to be_an_existing_file

      #
      # Rakefile
      #
      expect('Rakefile').to have_file_content <<-END
require 'rake'
require 'hanami/rake_tasks'

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
  task default: :spec
rescue LoadError
end
END

      #
      # spec/spec_helper.rb
      #
      expect("spec/spec_helper.rb").to have_file_content <<-END
# Require this file for unit tests
ENV['HANAMI_ENV'] ||= 'test'

require_relative '../config/environment'
Hanami.boot
Hanami::Utils.require!("\#{__dir__}/support")

# This file was generated by the `rspec --init` command. Conventionally, all
# specs live under a `spec` directory, which RSpec adds to the `$LOAD_PATH`.
# The generated `.rspec` file contains `--require spec_helper` which will cause
# this file to always be loaded, without a need to explicitly require it in any
# files.
#
# Given that it is always loaded, you are encouraged to keep this file as
# light-weight as possible. Requiring heavyweight dependencies from this file
# will add to the boot time of your test suite on EVERY test run, even for an
# individual file that may not need all of that loaded. Instead, consider making
# a separate helper file that requires the additional dependencies and performs
# the additional setup, and require it from the spec files that actually need
# it.
#
# The `.rspec` file also contains a few flags that are not defaults but that
# users commonly want.
#
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  # rspec-expectations config goes here. You can use an alternate
  # assertion/expectation library such as wrong or the stdlib/minitest
  # assertions if you prefer.
  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`, e.g.:
    #     be_bigger_than(2).and_smaller_than(4).description
    #     # => "be bigger than 2 and smaller than 4"
    # ...rather than:
    #     # => "be bigger than 2"
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end

# The settings below are suggested to provide a good initial experience
# with RSpec, but feel free to customize to your heart's content.
=begin
  # These two settings work together to allow you to limit a spec run
  # to individual examples or groups you care about by tagging them with
  # `:focus` metadata. When nothing is tagged with `:focus`, all examples
  # get run.
  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  # Allows RSpec to persist some state between runs in order to support
  # the `--only-failures` and `--next-failure` CLI options. We recommend
  # you configure your source control system to ignore this file.
  config.example_status_persistence_file_path = "spec/examples.txt"

  # Limits the available syntax to the non-monkey patched syntax that is
  # recommended. For more details, see:
  #   - http://myronmars.to/n/dev-blog/2012/06/rspecs-new-expectation-syntax
  #   - http://teaisaweso.me/blog/2013/05/27/rspecs-new-message-expectation-syntax/
  #   - http://myronmars.to/n/dev-blog/2014/05/notable-changes-in-rspec-3#new__config_option_to_disable_rspeccore_monkey_patching
  config.disable_monkey_patching!

  # This setting enables warnings. It's recommended, but in many cases may
  # be too noisy due to issues in dependencies.
  config.warnings = false

  # Many RSpec users commonly either run the entire suite or an individual
  # file, and it's useful to allow more verbose output when running an
  # individual spec file.
  if config.files_to_run.one?
    # Use the documentation formatter for detailed output,
    # unless a formatter has already been configured
    # (e.g. via a command-line flag).
    config.default_formatter = 'doc'
  end

  # Print the 10 slowest examples and example groups at the
  # end of the spec run, to help surface which specs are running
  # particularly slow.
  config.profile_examples = 10

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = :random

  # Seed global randomization in this process using the `--seed` CLI option.
  # Setting this allows you to use `--seed` to deterministically reproduce
  # test failures related to randomization by passing the same `--seed` value
  # as the one that triggered the failure.
  Kernel.srand config.seed
=end
end
END

      #
      # spec/features_helper.rb
      #
      expect("spec/features_helper.rb").to have_file_content <<-END
# Require this file for feature tests
require_relative './spec_helper'

require 'capybara'
require 'capybara/rspec'

RSpec.configure do |config|
  config.include RSpec::FeatureExampleGroup

  config.include Capybara::DSL,           feature: true
  config.include Capybara::RSpecMatchers, feature: true
end
END

      #
      # .gitignore
      #
      expect(".gitignore").to have_file_content <<-END
/db/*.sqlite
/public/assets*
/tmp
END

      #
      # apps/web/application.rb
      #
      expect("apps/web/application.rb").to have_file_content <<-END
require 'hanami/helpers'
require 'hanami/assets'

module Web
  class Application < Hanami::Application
    configure do
      ##
      # BASIC
      #

      # Define the root path of this application.
      # All paths specified in this configuration are relative to path below.
      #
      root __dir__

      # Relative load paths where this application will recursively load the
      # code.
      #
      # When you add new directories, remember to add them here.
      #
      load_paths << [
        'controllers',
        'views'
      ]

      # Handle exceptions with HTTP statuses (true) or don't catch them (false).
      # Defaults to true.
      # See: http://www.rubydoc.info/gems/hanami-controller/#Exceptions_management
      #
      # handle_exceptions true

      ##
      # HTTP
      #

      # Routes definitions for this application
      # See: http://www.rubydoc.info/gems/hanami-router#Usage
      #
      routes 'config/routes'

      # URI scheme used by the routing system to generate absolute URLs
      # Defaults to "http"
      #
      # scheme 'https'

      # URI host used by the routing system to generate absolute URLs
      # Defaults to "localhost"
      #
      # host 'example.org'

      # URI port used by the routing system to generate absolute URLs
      # Argument: An object coercible to integer, defaults to 80 if the scheme
      # is http and 443 if it's https
      #
      # This should only be configured if app listens to non-standard ports
      #
      # port 443

      # Enable cookies
      # Argument: boolean to toggle the feature
      #           A Hash with options
      #
      # Options:
      #   :domain   - The domain (String - nil by default, not required)
      #   :path     - Restrict cookies to a relative URI
      #               (String - nil by default)
      #   :max_age  - Cookies expiration expressed in seconds
      #               (Integer - nil by default)
      #   :secure   - Restrict cookies to secure connections
      #               (Boolean - Automatically true when using HTTPS)
      #               See #scheme and #ssl?
      #   :httponly - Prevent JavaScript access (Boolean - true by default)
      #
      # cookies true
      # or
      # cookies max_age: 300

      # Enable sessions
      # Argument: Symbol the Rack session adapter
      #           A Hash with options
      #
      # See: http://www.rubydoc.info/gems/rack/Rack/Session/Cookie
      #
      # sessions :cookie, secret: ENV['WEB_SESSIONS_SECRET']

      # Configure Rack middleware for this application
      #
      # middleware.use Rack::Protection

      # Default format for the requests that don't specify an HTTP_ACCEPT header
      # Argument: A symbol representation of a mime type, defaults to :html
      #
      # default_request_format :html

      # Default format for responses that don't consider the request format
      # Argument: A symbol representation of a mime type, defaults to :html
      #
      # default_response_format :html

      ##
      # TEMPLATES
      #

      # The layout to be used by all views
      #
      layout :application # It will load Web::Views::ApplicationLayout

      # The relative path to templates
      #
      templates 'templates'

      ##
      # ASSETS
      #
      assets do
        # JavaScript compressor
        #
        # Supported engines:
        #
        #   * :builtin
        #   * :uglifier
        #   * :yui
        #   * :closure
        #
        # See: https://guides.hanamirb.org/assets/compressors
        #
        # In order to skip JavaScript compression comment the following line
        javascript_compressor :builtin

        # Stylesheet compressor
        #
        # Supported engines:
        #
        #   * :builtin
        #   * :yui
        #   * :sass
        #
        # See: https://guides.hanamirb.org/assets/compressors
        #
        # In order to skip stylesheet compression comment the following line
        stylesheet_compressor :builtin

        # Specify sources for assets
        #
        sources << [
          'assets'
        ]
      end

      ##
      # SECURITY
      #

      # X-Frame-Options is a HTTP header supported by modern browsers.
      # It determines if a web page can or cannot be included via <frame> and
      # <iframe> tags by untrusted domains.
      #
      # Web applications can send this header to prevent Clickjacking attacks.
      #
      # Read more at:
      #
      #   * https://developer.mozilla.org/en-US/docs/Web/HTTP/X-Frame-Options
      #   * https://www.owasp.org/index.php/Clickjacking
      #
      security.x_frame_options 'DENY'

      # X-Content-Type-Options prevents browsers from interpreting files as
      # something else than declared by the content type in the HTTP headers.
      #
      # Read more at:
      #
      #   * https://www.owasp.org/index.php/OWASP_Secure_Headers_Project#X-Content-Type-Options
      #   * https://msdn.microsoft.com/en-us/library/gg622941%28v=vs.85%29.aspx
      #   * https://blogs.msdn.microsoft.com/ie/2008/09/02/ie8-security-part-vi-beta-2-update
      #
      security.x_content_type_options 'nosniff'

      # X-XSS-Protection is a HTTP header to determine the behavior of the
      # browser in case an XSS attack is detected.
      #
      # Read more at:
      #
      #   * https://www.owasp.org/index.php/Cross-site_Scripting_(XSS)
      #   * https://www.owasp.org/index.php/OWASP_Secure_Headers_Project#X-XSS-Protection
      #
      security.x_xss_protection '1; mode=block'

      # Content-Security-Policy (CSP) is a HTTP header supported by modern
      # browsers. It determines trusted sources of execution for dynamic
      # contents (JavaScript) or other web related assets: stylesheets, images,
      # fonts, plugins, etc.
      #
      # Web applications can send this header to mitigate Cross Site Scripting
      # (XSS) attacks.
      #
      # The default value allows images, scripts, AJAX, fonts and CSS from the
      # same origin, and does not allow any other resources to load (eg object,
      # frame, media, etc).
      #
      # Inline JavaScript is NOT allowed. To enable it, please use:
      # "script-src 'unsafe-inline'".
      #
      # Content Security Policy introduction:
      #
      #  * http://www.html5rocks.com/en/tutorials/security/content-security-policy/
      #  * https://www.owasp.org/index.php/Content_Security_Policy
      #  * https://www.owasp.org/index.php/Cross-site_Scripting_%28XSS%29
      #
      # Inline and eval JavaScript risks:
      #
      #   * http://www.html5rocks.com/en/tutorials/security/content-security-policy/#inline-code-considered-harmful
      #   * http://www.html5rocks.com/en/tutorials/security/content-security-policy/#eval-too
      #
      # Content Security Policy usage:
      #
      #  * http://content-security-policy.com/
      #  * https://developer.mozilla.org/en-US/docs/Web/Security/CSP/Using_Content_Security_Policy
      #
      # Content Security Policy references:
      #
      #  * https://developer.mozilla.org/en-US/docs/Web/Security/CSP/CSP_policy_directives
      #
      security.content_security_policy %{
        form-action 'self';
        frame-ancestors 'self';
        base-uri 'self';
        default-src 'none';
        script-src 'self';
        connect-src 'self';
        img-src 'self' https: data:;
        style-src 'self' 'unsafe-inline' https:;
        font-src 'self';
        object-src 'none';
        plugin-types application/pdf;
        child-src 'self';
        frame-src 'self';
        media-src 'self'
      }

      ##
      # FRAMEWORKS
      #

      # Configure the code that will yield each time Web::Action is included
      # This is useful for sharing common functionality
      #
      # See: http://www.rubydoc.info/gems/hanami-controller#Configuration
      controller.prepare do
        # include MyAuthentication # included in all the actions
        # before :authenticate!    # run an authentication before callback
      end

      # Configure the code that will yield each time Web::View is included
      # This is useful for sharing common functionality
      #
      # See: http://www.rubydoc.info/gems/hanami-view#Configuration
      view.prepare do
        include Hanami::Helpers
        include Web::Assets::Helpers
      end
    end

    ##
    # DEVELOPMENT
    #
    configure :development do
      # Don't handle exceptions, render the stack trace
      handle_exceptions false
    end

    ##
    # TEST
    #
    configure :test do
      # Don't handle exceptions, render the stack trace
      handle_exceptions false
    end

    ##
    # PRODUCTION
    #
    configure :production do
      # scheme 'https'
      # host   'example.org'
      # port   443

      assets do
        # Don't compile static assets in production mode (eg. Sass, ES6)
        #
        # See: http://www.rubydoc.info/gems/hanami-assets#Configuration
        compile false

        # Use fingerprint file name for asset paths
        #
        # See: https://guides.hanamirb.org/assets/overview
        fingerprint true

        # Content Delivery Network (CDN)
        #
        # See: https://guides.hanamirb.org/assets/content-delivery-network
        #
        # scheme 'https'
        # host   'cdn.example.org'
        # port   443

        # Subresource Integrity
        #
        # See: https://guides.hanamirb.org/assets/content-delivery-network/#subresource-integrity
        subresource_integrity :sha256
      end
    end
  end
end
END

      #
      # apps/web/config/routes.rb
      #
      expect("apps/web/config/routes.rb").to have_file_content <<-END
# Configure your routes here
# See: https://guides.hanamirb.org/routing/overview
#
# Example:
# get '/hello', to: ->(env) { [200, {}, ['Hello from Hanami!']] }
END

      #
      # apps/web/views/application_layout.rb
      #
      expect("apps/web/views/application_layout.rb").to have_file_content <<-END
module Web
  module Views
    class ApplicationLayout
      include Web::Layout
    end
  end
end
END

      #
      # apps/web/templates/application.html.erb
      #
      expect("apps/web/templates/application.html.erb").to have_file_content <<-END
<!DOCTYPE html>
<html>
  <head>
    <title>Web</title>
    <%= favicon %>
  </head>
  <body>
    <%= yield %>
  </body>
</html>
END

      #
      # apps/web/assets/favicon.ico
      #
      expect("apps/web/assets/favicon.ico").to be_an_existing_file

      #
      # apps/web/controllers/.gitkeep
      #
      expect("apps/web/controllers/.gitkeep").to be_an_existing_file

      #
      # apps/web/assets/images/.gitkeep
      #
      expect("apps/web/assets/images/.gitkeep").to be_an_existing_file

      #
      # apps/web/assets/javascripts/.gitkeep
      #
      expect("apps/web/assets/javascripts/.gitkeep").to be_an_existing_file

      #
      # apps/web/assets/stylesheets/.gitkeep
      #
      expect("apps/web/assets/stylesheets/.gitkeep").to be_an_existing_file

      #
      # spec/web/features/.gitkeep
      #
      expect("spec/web/features/.gitkeep").to be_an_existing_file

      #
      # spec/web/controllers/.gitkeep
      #
      expect("spec/web/controllers/.gitkeep").to be_an_existing_file
    end
  end

  context "with underscored project name" do
    it_behaves_like "a new project" do
      let(:input) { "cool_name" }
    end
  end

  context "with dashed project name" do
    it_behaves_like "a new project" do
      let(:input) { "awesome-project" }
    end
  end

  context "with camel case project name" do
    it_behaves_like "a new project" do
      let(:input) { "CaMElCaSE" }
    end
  end

  context "with dot as project name" do
    before do
      root.mkpath
    end

    let(:root) { Pathname.new(Dir.pwd).join("tmp", "aruba", dir) }
    let(:project) { "terrific_product" }
    let(:dir) { "terrific product" }

    it "generates project" do
      cd(dir) do
        run_command "hanami new ."
      end

      [
        "create  lib/#{project}.rb",
        "create  lib/#{project}/entities/.gitkeep",
        "create  lib/#{project}/repositories/.gitkeep",
        "create  lib/#{project}/mailers/.gitkeep",
        "create  lib/#{project}/mailers/templates/.gitkeep",
        "create  spec/#{project}/entities/.gitkeep",
        "create  spec/#{project}/repositories/.gitkeep",
        "create  spec/#{project}/mailers/.gitkeep"
      ].each do |output|
        expect(all_output).to match(/#{output}/)
      end

      within_project_directory(dir) do
        #
        # .hanamirc
        #
        expect('.hanamirc').to have_file_content %r{project=#{project}}
      end
    end
  end

  context "with missing name" do
    it "fails" do
      output = <<-OUT
ERROR: "hanami new" was called with no arguments
Usage: "hanami new PROJECT"
      OUT

      run_command "hanami new", output, exit_status: 1
    end
  end

  it 'prints help message' do
    output = <<-OUT
Command:
  hanami new

Usage:
  hanami new PROJECT

Description:
  Generate a new Hanami project

Arguments:
  PROJECT             	# REQUIRED The project name

Options:
  --database=VALUE, -d VALUE      	# Database (mysql/mysql2/postgresql/postgres/sqlite/sqlite3), default: "sqlite"
  --application-name=VALUE        	# App name, default: "web"
  --application-base-url=VALUE    	# App base URL, default: "/"
  --template=VALUE                	# Template engine (erb/haml/slim), default: "erb"
  --test=VALUE                    	# Project testing framework (rspec/minitest), default: "rspec"
  --[no-]hanami-head              	# Use Hanami HEAD (true/false), default: false
  --help, -h                      	# Print this help

Examples:
  hanami new bookshelf                     # Basic usage
  hanami new bookshelf --test=rspec        # Setup RSpec testing framework
  hanami new bookshelf --database=postgres # Setup Postgres database
  hanami new bookshelf --template=slim     # Setup Slim template engine
  hanami new bookshelf --hanami-head       # Use Hanami HEAD
OUT

    run_command 'hanami new --help', output
  end
end
