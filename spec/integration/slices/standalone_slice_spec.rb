# frozen_string_literal: true

require "rack/test"

RSpec.describe "Slices / Standalone slices", :app_integration do
  # No Hanami::App is ever defined in these examples. These modules are removed
  # between examples by the :app_integration teardown.
  let(:app_modules) { %i[PagesFeature BooksFeature ParentFeature] }

  def write_slice(module_name, path_name)
    write "#{path_name}/lib/#{path_name}.rb", <<~RUBY
      require "hanami"

      module #{module_name}
        class Slice < Hanami::Slice
          config.root = File.expand_path("../slice", __dir__)
          config.logger.stream = File::NULL
        end
      end
    RUBY

    write "#{path_name}/slice/config/routes.rb", <<~RUBY
      require "hanami/routes"

      module #{module_name}
        class Routes < Hanami::Routes
          get "/pages", to: "index", as: :pages
          get "/pages/:slug", to: "show", as: :page
        end
      end
    RUBY

    write "#{path_name}/slice/actions/index.rb", <<~RUBY
      require "hanami/action"

      module #{module_name}
        module Actions
          class Index < Hanami::Action
            def handle(request, response)
              response.body = "pages index (script_name=\#{request.env["SCRIPT_NAME"]})"
            end
          end
        end
      end
    RUBY

    write "#{path_name}/slice/actions/show.rb", <<~RUBY
      require "hanami/action"

      module #{module_name}
        module Actions
          class Show < Hanami::Action
            def handle(request, response)
              response.body = "page \#{request.params[:slug]}"
            end
          end
        end
      end
    RUBY
  end

  specify "a slice can be defined, prepared, and booted without an app" do
    with_tmp_directory(Dir.mktmpdir) do
      write_slice("PagesFeature", "pages_feature")
      require File.join(Dir.pwd, "pages_feature/lib/pages_feature")

      expect(Hanami.app?).to be false

      slice = PagesFeature::Slice

      # With no app in the process, the slice is its own host
      expect(slice.host).to be slice
      expect(slice).to be_host

      expect(slice.prepare).to be slice
      expect(slice.prepared?).to be true

      # Components load from the slice's own gem-shaped root
      expect(slice["actions.index"]).to be_an_instance_of PagesFeature::Actions::Index

      # The slice provisions the components it would otherwise import from the app
      expect(slice["logger"]).to respond_to :info
      expect(slice["inflector"]).to be slice.inflector
      expect(slice["notifications"]).to be

      expect(slice.boot).to be slice
      expect(slice.booted?).to be true
      expect(Hanami.app?).to be false
    end
  end

  specify "a standalone slice builds its own config and defaults its root to the working directory" do
    with_tmp_directory(Dir.mktmpdir) do
      module BooksFeature
        class Slice < Hanami::Slice
        end
      end

      expect(BooksFeature::Slice.config).to be_an_instance_of Hanami::Config
      expect(BooksFeature::Slice.config.env).to eq Hanami.env
      expect(BooksFeature::Slice.root).to eq Pathname(Dir.pwd)
    end
  end

  describe "serving a standalone slice as a Rack app" do
    include Rack::Test::Methods

    def app
      PagesFeature::Slice
    end

    specify "routing, params, and named path generation work without an app" do
      with_tmp_directory(Dir.mktmpdir) do
        write_slice("PagesFeature", "pages_feature")
        require File.join(Dir.pwd, "pages_feature/lib/pages_feature")

        PagesFeature::Slice.prepare

        get "/pages"
        expect(last_response.status).to eq 200
        expect(last_response.body).to eq "pages index (script_name=)"

        get "/pages/about"
        expect(last_response.status).to eq 200
        expect(last_response.body).to eq "page about"

        expect(PagesFeature::Slice.router.path(:page, slug: "about")).to eq "/pages/about"
        expect(Hanami.app?).to be false
      end
    end
  end

  specify "a standalone slice can register nested slices" do
    with_tmp_directory(Dir.mktmpdir) do
      write_slice("ParentFeature", "parent_feature")
      require File.join(Dir.pwd, "parent_feature/lib/parent_feature")

      write "admin/slice.rb", <<~RUBY
        module ParentFeature
          module Admin
            class Slice < Hanami::Slice
              config.root = __dir__
            end
          end
        end
      RUBY
      require File.join(Dir.pwd, "admin/slice")

      write "admin/actions/index.rb", <<~RUBY
        require "hanami/action"

        module ParentFeature
          module Admin
            module Actions
              class Index < Hanami::Action
              end
            end
          end
        end
      RUBY

      ParentFeature::Slice.register_slice(:admin, ParentFeature::Admin::Slice)
      ParentFeature::Slice.prepare

      admin = ParentFeature::Slice.slices[:admin]
      expect(admin).to be ParentFeature::Admin::Slice
      expect(admin.parent).to be ParentFeature::Slice

      admin.prepare
      expect(admin["actions.index"]).to be_an_instance_of ParentFeature::Admin::Actions::Index
    end
  end

  specify "subclassing a slice-configurable class outside any slice namespace is a no-op" do
    expect {
      Class.new(Hanami::Action)
    }.not_to raise_error
  end
end
