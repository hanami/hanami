# frozen_string_literal: true

require "hanami"

RSpec.describe "App view / Config / Paths", :app_integration do
  before do
    with_directory(make_tmp_directory) do
      write "config/app.rb", <<~RUBY
        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "app/view.rb", <<~RUBY
        # auto_register: false

        require "hanami/view"

        module TestApp
          class View < Hanami::View
          end
        end
      RUBY

      require "hanami/setup"
      before_prepare if respond_to?(:before_prepare)
      require "hanami/prepare"
    end
  end

  subject(:paths) { view_class.config.paths }

  describe "app view" do
    let(:view_class) { TestApp::View }

    it "is 'app/templates/'" do
      expect(paths.map(&:dir)).to eq [Hanami.app.root.join("app", "templates")]
    end

    context "custom config in app" do
      def before_prepare
        TestApp::App.config.views.paths = ["/custom/dir"]
      end

      it "uses the custom config" do
        expect(paths.map(&:dir)).to eq [Pathname("/custom/dir")]
      end
    end
  end

  describe "slice view" do
    subject(:view_class) { Main::View }

    def before_prepare
      write "slices/main/view.rb", <<~RUBY
        # auto_register: false

        module Main
          class View < TestApp::View
          end
        end
      RUBY
    end

    it "is 'templates/' within the slice dir" do
      expect(paths.map(&:dir)).to eq [Main::Slice.root.join("templates")]
    end

    context "custom config in app" do
      def before_prepare
        super
        TestApp::App.config.views.paths = ["/custom/dir"]
      end

      it "uses the custom config" do
        expect(paths.map(&:dir)).to eq [Pathname("/custom/dir")]
      end
    end

    context "custom config in slice" do
      def before_prepare
        super

        write "config/slices/main.rb", <<~RUBY
          module Main
            class Slice < Hanami::Slice
              config.views.paths = ["/custom/slice/dir"]
            end
          end
        RUBY
      end

      it "uses the custom config" do
        expect(paths.map(&:dir)).to eq [Pathname("/custom/slice/dir")]
      end
    end

    context "custom config in app and slice" do
      def before_prepare
        super

        TestApp::App.config.views.paths = ["/custom/dir"]

        write "config/slices/main.rb", <<~RUBY
          module Main
            class Slice < Hanami::Slice
              config.views.paths = ["/custom/slice/dir"]
            end
          end
        RUBY
      end

      it "uses the custom config from the slice" do
        expect(paths.map(&:dir)).to eq [Pathname("/custom/slice/dir")]
      end
    end
  end
end
