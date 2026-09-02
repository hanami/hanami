# frozen_string_literal: true

RSpec.describe "Code loading / Reloading", :app_integration do
  subject(:app) { Hanami.app }

  def reload!
    with_directory(@dir) { app.reload! }
  end

  describe "app code" do
    before do
      @dir = make_tmp_directory

      with_directory(@dir) do
        write "config/app.rb", <<~'RUBY'
          require "hanami"

          module TestApp
            class App < Hanami::App
            end
          end
        RUBY

        write "app/greeter.rb", <<~'RUBY'
          module TestApp
            class Greeter
              def call = "hello"
            end
          end
        RUBY

        require "hanami/prepare"
      end
    end

    specify "picks up changes to an existing component" do
      expect(app["greeter"].call).to eq "hello"

      with_directory(@dir) do
        rewrite "app/greeter.rb", <<~'RUBY'
          module TestApp
            class Greeter
              def call = "goodbye"
            end
          end
        RUBY
      end

      reload!

      expect(app["greeter"].call).to eq "goodbye"
    end

    specify "picks up newly added files" do
      expect(app.key?("farewell")).to be false

      with_directory(@dir) do
        write "app/farewell.rb", <<~'RUBY'
          module TestApp
            class Farewell
              def call = "bye"
            end
          end
        RUBY
      end

      reload!

      expect(app["farewell"].call).to eq "bye"
    end

    specify "drops components whose files have been deleted" do
      expect(app["greeter"].call).to eq "hello"

      FileUtils.rm File.join(@dir, "app", "greeter.rb")

      reload!

      expect(app.key?("greeter")).to be false
    end

    specify "replaces stale constants rather than reusing them" do
      before_reload = TestApp::Greeter

      reload!

      expect(TestApp::Greeter).to be
      expect(TestApp::Greeter).not_to equal before_reload
    end

    specify "preserves the app class object so `run Hanami.app` stays valid" do
      app_class = Hanami.app

      reload!

      expect(Hanami.app).to equal app_class
    end

    specify "leaves the app prepared and resolvable afterwards" do
      reload!

      expect(app).to be_prepared
      expect(app["greeter"]).to be_an_instance_of TestApp::Greeter
    end

    specify "reloads repeatedly" do
      3.times do |i|
        with_directory(@dir) do
          rewrite "app/greeter.rb", <<~RUBY
            module TestApp
              class Greeter
                def call = "hello #{i}"
              end
            end
          RUBY
        end

        reload!

        expect(app["greeter"].call).to eq "hello #{i}"
      end
    end
  end

  describe "unloading" do
    before do
      @dir = make_tmp_directory

      with_directory(@dir) do
        write "config/app.rb", <<~'RUBY'
          require "hanami"

          module TestApp
            class App < Hanami::App
            end
          end
        RUBY

        write "app/greeter.rb", <<~'RUBY'
          module TestApp
            class Greeter
              def call = "hello"
            end
          end
        RUBY
      end
    end

    specify "unloading a prepared app leaves it unprepared, and preparable again" do
      with_directory(@dir) { require "hanami/prepare" }

      app.unload!

      expect(app).not_to be_prepared
      expect(defined?(TestApp::Greeter)).to be nil
      expect(TestApp.const_defined?(:Container, false)).to be false

      with_directory(@dir) { app.prepare }

      expect(app).to be_prepared
      expect(app["greeter"].call).to eq "hello"
    end

    specify "unloading an app that was never prepared does nothing" do
      with_directory(@dir) { require "hanami/setup" }

      expect { app.unload! }.not_to raise_error
      expect(app).not_to be_prepared
    end

    specify "reloading an app that was never prepared simply prepares it" do
      with_directory(@dir) { require "hanami/setup" }

      reload!

      expect(app).to be_prepared
      expect(app["greeter"].call).to eq "hello"
    end
  end

  describe "routes" do
    before do
      @dir = make_tmp_directory

      with_directory(@dir) do
        write "config/app.rb", <<~'RUBY'
          require "hanami"

          module TestApp
            class App < Hanami::App
            end
          end
        RUBY

        write "config/routes.rb", <<~'RUBY'
          module TestApp
            class Routes < Hanami::Routes
              get "/original", to: ->(*) { [200, {}, ["original"]] }
            end
          end
        RUBY

        require "hanami/prepare"
      end
    end

    specify "picks up changes to config/routes.rb" do
      expect(Rack::MockRequest.new(app).get("/original").body).to eq "original"

      with_directory(@dir) do
        rewrite "config/routes.rb", <<~'RUBY'
          module TestApp
            class Routes < Hanami::Routes
              get "/changed", to: ->(*) { [200, {}, ["changed"]] }
            end
          end
        RUBY
      end

      reload!

      expect(Rack::MockRequest.new(app).get("/changed").body).to eq "changed"
      expect(Rack::MockRequest.new(app).get("/original").status).to eq 404
    end
  end

  describe "slices" do
    before do
      @dir = make_tmp_directory

      with_directory(@dir) do
        write "config/app.rb", <<~'RUBY'
          require "hanami"

          module TestApp
            class App < Hanami::App
            end
          end
        RUBY

        write "slices/main/greeter.rb", <<~'RUBY'
          module Main
            class Greeter
              def call = "main hello"
            end
          end
        RUBY

        require "hanami/prepare"
      end
    end

    specify "reloads code in nested slices" do
      expect(Main::Slice["greeter"].call).to eq "main hello"

      with_directory(@dir) do
        rewrite "slices/main/greeter.rb", <<~'RUBY'
          module Main
            class Greeter
              def call = "main goodbye"
            end
          end
        RUBY
      end

      reload!

      expect(Main::Slice["greeter"].call).to eq "main goodbye"
    end

    specify "replaces slice class objects, keeping the registry pointed at the current one" do
      # Unlike the app class, slice classes are rebuilt so that changes to their definition files
      # take effect. Anything holding a slice class across a reload will hold a stale one.
      slice_class = Main::Slice

      reload!

      expect(Main::Slice).not_to equal slice_class
      expect(app.slices[:main]).to equal Main::Slice
    end
  end

  describe "providers" do
    before do
      @dir = make_tmp_directory

      with_directory(@dir) do
        write "config/app.rb", <<~'RUBY'
          require "hanami"

          module TestApp
            class App < Hanami::App
            end
          end
        RUBY

        write "config/providers/tracker.rb", <<~'RUBY'
          # Logged to a file rather than memory: this provider file is re-evaluated on each
          # reload, so anything held in a constant or ivar here would be reset along with it.
          Hanami.app.register_provider(:tracker) do
            start do
              File.open(File.join(Hanami.app.root, "tracker.log"), "a") { _1.puts("started") }
              register "tracker", Object.new
            end

            stop do
              File.open(File.join(Hanami.app.root, "tracker.log"), "a") { _1.puts("stopped") }
            end
          end
        RUBY

        require "hanami/prepare"
      end
    end

    def tracker_events
      path = File.join(@dir, "tracker.log")
      File.exist?(path) ? File.readlines(path, chomp: true) : []
    end

    specify "stops providers on teardown and restarts them on demand" do
      app.start(:tracker)
      expect(tracker_events).to eq %w[started]

      reload!

      expect(tracker_events).to eq %w[started stopped]

      app.start(:tracker)
      expect(tracker_events).to eq %w[started stopped started]
    end

    specify "re-evaluates provider files, picking up their changes" do
      app.start(:tracker)
      expect(app["tracker"]).to be_an_instance_of Object

      with_directory(@dir) do
        rewrite "config/providers/tracker.rb", <<~'RUBY'
          Hanami.app.register_provider(:tracker) do
            start do
              register "tracker", "replaced!"
            end
          end
        RUBY
      end

      reload!
      app.start(:tracker)

      expect(app["tracker"]).to eq "replaced!"
    end
  end

  describe "settings" do
    before do
      @dir = make_tmp_directory

      with_directory(@dir) do
        write "config/app.rb", <<~'RUBY'
          require "hanami"

          module TestApp
            class App < Hanami::App
            end
          end
        RUBY

        write "config/settings.rb", <<~'RUBY'
          module TestApp
            class Settings < Hanami::Settings
              setting :one
            end
          end
        RUBY

        ENV["ONE"] = "first"
        ENV["TWO"] = "second"

        require "hanami/prepare"
      end
    end

    after { ENV.delete("ONE"); ENV.delete("TWO") }

    specify "picks up changes to config/settings.rb" do
      expect(app["settings"].one).to eq "first"
      expect(app["settings"]).not_to respond_to(:two)

      with_directory(@dir) do
        rewrite "config/settings.rb", <<~'RUBY'
          module TestApp
            class Settings < Hanami::Settings
              setting :one
              setting :two
            end
          end
        RUBY
      end

      reload!

      expect(app["settings"].one).to eq "first"
      expect(app["settings"].two).to eq "second"
    end
  end

  describe "slice churn" do
    before do
      @dir = make_tmp_directory

      with_directory(@dir) do
        write "config/app.rb", <<~'RUBY'
          require "hanami"

          module TestApp
            class App < Hanami::App
            end
          end
        RUBY

        write "slices/main/greeter.rb", <<~'RUBY'
          module Main
            class Greeter
              def call = "main"
            end
          end
        RUBY

        require "hanami/prepare"
      end
    end

    def reload! = with_directory(@dir) { app.reload! }

    specify "picks up a slice added on disk" do
      expect(app.slices.keys).to eq [:main]

      with_directory(@dir) do
        write "slices/admin/greeter.rb", <<~'RUBY'
          module Admin
            class Greeter
              def call = "admin"
            end
          end
        RUBY
      end

      reload!

      expect(app.slices.keys).to contain_exactly(:main, :admin)
      expect(Admin::Slice["greeter"].call).to eq "admin"
    end

    specify "drops a slice removed from disk" do
      expect(Main::Slice["greeter"].call).to eq "main"

      FileUtils.rm_rf File.join(@dir, "slices", "main")

      reload!

      expect(app.slices.keys).to eq []
    end

    specify "picks up changes to a slice definition file" do
      with_directory(@dir) do
        write "config/slices/main.rb", <<~'RUBY'
          module Main
            class Slice < Hanami::Slice
              register "marker", "before"
            end
          end
        RUBY
      end

      reload!
      expect(Main::Slice["marker"]).to eq "before"

      with_directory(@dir) do
        rewrite "config/slices/main.rb", <<~'RUBY'
          module Main
            class Slice < Hanami::Slice
              register "marker", "after!!"
            end
          end
        RUBY
      end

      reload!

      expect(Main::Slice["marker"]).to eq "after!!"
    end

    specify "existing slices keep working across a reload that adds one" do
      with_directory(@dir) do
        write "slices/admin/greeter.rb", <<~'RUBY'
          module Admin
            class Greeter
              def call = "admin"
            end
          end
        RUBY
      end

      reload!

      expect(Main::Slice["greeter"].call).to eq "main"
      expect(Admin::Slice["greeter"].call).to eq "admin"
    end
  end

  describe "nested slices" do
    before do
      @dir = make_tmp_directory

      with_directory(@dir) do
        write "config/app.rb", <<~'RUBY'
          require "hanami"

          module TestApp
            class App < Hanami::App
            end
          end
        RUBY

        write "slices/main/greeter.rb", <<~'RUBY'
          module Main
            class Greeter
              def call = "main v1"
            end
          end
        RUBY

        write "slices/main/slices/nested/greeter.rb", <<~'RUBY'
          module Main
            module Nested
              class Greeter
                def call = "nested v1"
              end
            end
          end
        RUBY

        require "hanami/prepare"
      end
    end

    specify "reloads code in nested slices" do
      expect(Main::Slice["greeter"].call).to eq "main v1"
      expect(Main::Nested::Slice["greeter"].call).to eq "nested v1"

      with_directory(@dir) do
        rewrite "slices/main/slices/nested/greeter.rb", <<~'RUBY'
          module Main
            module Nested
              class Greeter
                def call = "nested v2"
              end
            end
          end
        RUBY
      end

      reload!

      expect(Main::Slice["greeter"].call).to eq "main v1"
      expect(Main::Nested::Slice["greeter"].call).to eq "nested v2"
    end

    specify "picks up a nested slice added on disk" do
      expect(Main::Slice.slices.keys).to eq [:nested]

      with_directory(@dir) do
        write "slices/main/slices/extra/greeter.rb", <<~'RUBY'
          module Main
            module Extra
              class Greeter
                def call = "extra"
              end
            end
          end
        RUBY
      end

      reload!

      expect(Main::Slice.slices.keys).to contain_exactly(:nested, :extra)
      expect(Main::Extra::Slice["greeter"].call).to eq "extra"
    end
  end

  describe "when a reload raises" do
    before do
      @dir = make_tmp_directory

      with_directory(@dir) do
        write "config/app.rb", <<~'RUBY'
          require "hanami"

          module TestApp
            class App < Hanami::App
            end
          end
        RUBY

        write "config/settings.rb", <<~'RUBY'
          module TestApp
            class Settings < Hanami::Settings
              setting :one
            end
          end
        RUBY

        ENV["ONE"] = "ok"

        require "hanami/prepare"
      end
    end

    after { ENV.delete("ONE") }

    specify "a later reload recovers once the offending file is fixed" do
      expect(app["settings"].one).to eq "ok"

      with_directory(@dir) do
        rewrite "config/settings.rb", <<~'RUBY'
          this_explodes_at_load_time!
        RUBY
      end

      # Settings are loaded during `prepare`, so this leaves the app torn down.
      expect { reload! }.to raise_error(NameError)
      expect(app).not_to be_prepared

      with_directory(@dir) do
        rewrite "config/settings.rb", <<~'RUBY'
          module TestApp
            class Settings < Hanami::Settings
              setting :one
              setting :two
            end
          end
        RUBY
        ENV["TWO"] = "recovered"
      end

      reload!

      expect(app).to be_prepared
      expect(app["settings"].two).to eq "recovered"
    end
  end

  describe "when code reloading is disabled" do
    before do
      @dir = make_tmp_directory

      with_directory(@dir) do
        write "config/app.rb", <<~'RUBY'
          require "hanami"

          module TestApp
            class App < Hanami::App
              config.code_reloading = false
            end
          end
        RUBY

        write "app/greeter.rb", <<~'RUBY'
          module TestApp
            class Greeter
              def call = "hello"
            end
          end
        RUBY

        require "hanami/prepare"
      end
    end

    specify "the app works as normal" do
      expect(app["greeter"].call).to eq "hello"
    end

    specify "the autoloader does no reloading bookkeeping" do
      expect(app.autoloader.reloading_enabled?).to be false
      expect(app.autoloader.unloadable_cpaths).to be_empty
    end

    specify "reloading raises rather than silently doing nothing" do
      expect { reload! }.to raise_error(Hanami::SliceLoadError, /code_reloading/)
    end
  end

  describe "code_reloading defaults" do
    def config_for(env, name)
      Hanami::Config.new(
        app_name: Hanami::SliceName.new(double(name: name), inflector: Dry::Inflector.new),
        env: env
      )
    end

    specify "on in development, off everywhere else" do
      expect(config_for(:development, "Dev::App").code_reloading).to be true
      expect(config_for(:production, "Prod::App").code_reloading).to be false
      expect(config_for(:test, "Test::App").code_reloading).to be false
    end
  end

  describe "code_reloading is an app-wide decision" do
    before do
      @dir = make_tmp_directory

      with_directory(@dir) do
        write "config/app.rb", <<~'RUBY'
          require "hanami"

          module TestApp
            class App < Hanami::App
            end
          end
        RUBY

        # Slices copy the app's config, so this slice carries its own value. It must be ignored:
        # reloading only part of the tree would leave this slice importing from a discarded
        # container.
        write "config/slices/main.rb", <<~'RUBY'
          module Main
            class Slice < Hanami::Slice
              config.code_reloading = false
            end
          end
        RUBY

        write "slices/main/greeter.rb", <<~'RUBY'
          module Main
            class Greeter
              def call = "main v1"
            end
          end
        RUBY

        require "hanami/prepare"
      end
    end

    specify "a slice opting out is ignored, and still reloads with the app" do
      expect(Main::Slice.config.code_reloading).to be false
      expect(Main::Slice.autoloader.reloading_enabled?).to be true

      expect(Main::Slice["greeter"].call).to eq "main v1"

      with_directory(@dir) do
        rewrite "slices/main/greeter.rb", <<~'RUBY'
          module Main
            class Greeter
              def call = "main v2"
            end
          end
        RUBY
      end

      reload!

      expect(Main::Slice["greeter"].call).to eq "main v2"
    end
  end
end
