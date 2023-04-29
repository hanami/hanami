# frozen_string_literal: true

RSpec.describe "App view / Slice configuration", :app_integration do
  before do
    with_directory(@dir = make_tmp_directory) do
      write "config/app.rb", <<~RUBY
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "app/view.rb", <<~RUBY
        require "hanami/view"

        module TestApp
          class View < Hanami::View
          end
        end
      RUBY

      require "hanami/setup"
    end
  end

  def prepare_app
    with_directory(@dir) { require "hanami/prepare" }
  end

  describe "inheriting from app-level base class" do
    describe "app-level base class" do
      it "applies default views config from the app", :aggregate_failures do
        prepare_app

        expect(TestApp::View.config.layouts_dir).to eq "layouts"
        expect(TestApp::View.config.layout).to eq "app"
      end

      it "applies views config from the app" do
        Hanami.app.config.views.layout = "app_layout"

        prepare_app

        expect(TestApp::View.config.layout).to eq "app_layout"
      end

      it "does not override config in the base class" do
        Hanami.app.config.views.layout = "app_layout"

        prepare_app

        TestApp::View.config.layout = "custom_layout"

        expect(TestApp::View.config.layout).to eq "custom_layout"
      end
    end

    describe "subclass in app" do
      before do
        with_directory(@dir) do
          write "app/views/articles/index.rb", <<~RUBY
            module TestApp
              module Views
                module Articles
                  class Index < TestApp::View
                  end
                end
              end
            end
          RUBY
        end
      end

      it "applies default views config from the app", :aggregate_failures do
        prepare_app

        expect(TestApp::Views::Articles::Index.config.layouts_dir).to eq "layouts"
        expect(TestApp::Views::Articles::Index.config.layout).to eq "app"
      end

      it "applies views config from the app" do
        Hanami.app.config.views.layout = "app_layout"

        prepare_app

        expect(TestApp::Views::Articles::Index.config.layout).to eq "app_layout"
      end

      it "applies config from the base class" do
        prepare_app

        TestApp::View.config.layout = "base_class_layout"

        expect(TestApp::Views::Articles::Index.config.layout).to eq "base_class_layout"
      end
    end

    describe "subclass in slice" do
      before do
        with_directory(@dir) do
          write "slices/admin/views/articles/index.rb", <<~RUBY
            module Admin
              module Views
                module Articles
                  class Index < TestApp::View
                  end
                end
              end
            end
          RUBY
        end
      end

      it "applies default views config from the app", :aggregate_failures do
        prepare_app

        expect(Admin::Views::Articles::Index.config.layouts_dir).to eq "layouts"
        expect(Admin::Views::Articles::Index.config.layout).to eq "app"
      end

      it "applies views config from the app" do
        Hanami.app.config.views.layout = "app_layout"

        prepare_app

        expect(Admin::Views::Articles::Index.config.layout).to eq "app_layout"
      end

      it "applies config from the base class" do
        prepare_app

        TestApp::View.config.layout = "base_class_layout"

        expect(Admin::Views::Articles::Index.config.layout).to eq "base_class_layout"
      end
    end
  end

  describe "inheriting from a slice-level base class, in turn inheriting from an app-level base class" do
    before do
      with_directory(@dir) do
        write "slices/admin/view.rb", <<~RUBY
          module Admin
            class View < TestApp::View
            end
          end
        RUBY
      end
    end

    describe "slice-level base class" do
      it "applies default views config from the app", :aggregate_failures do
        prepare_app

        expect(Admin::View.config.layouts_dir).to eq "layouts"
        expect(Admin::View.config.layout).to eq "app"
      end

      it "applies views config from the app" do
        Hanami.app.config.views.layout = "app_layout"

        prepare_app

        expect(Admin::View.config.layout).to eq "app_layout"
      end

      it "applies config from the app base class" do
        prepare_app

        TestApp::View.config.layout = "app_base_class_layout"

        expect(Admin::View.config.layout).to eq "app_base_class_layout"
      end

      context "slice views config present" do
        before do
          with_directory(@dir) do
            write "config/slices/admin.rb", <<~RUBY
              module Admin
                class Slice < Hanami::Slice
                  config.views.layout = "slice_layout"
                end
              end
            RUBY
          end
        end

        it "applies views config from the slice" do
          prepare_app

          expect(Admin::View.config.layout).to eq "slice_layout"
        end

        it "prefers views config from the slice over config from the app-level base class" do
          prepare_app

          TestApp::View.config.layout = "app_base_class_layout"

          expect(Admin::View.config.layout).to eq "slice_layout"
        end

        it "prefers config from the base class over views config from the slice" do
          prepare_app

          TestApp::View.config.layout = "app_base_class_layout"
          Admin::View.config.layout = "slice_base_class_layout"

          expect(Admin::View.config.layout).to eq "slice_base_class_layout"
        end
      end
    end

    describe "subclass in slice" do
      before do
        with_directory(@dir) do
          write "slices/admin/views/articles/index.rb", <<~RUBY
            module Admin
              module Views
                module Articles
                  class Index < Admin::View
                  end
                end
              end
            end
          RUBY
        end
      end

      it "applies default views config from the app", :aggregate_failures do
        prepare_app

        expect(Admin::Views::Articles::Index.config.layouts_dir).to eq "layouts"
        expect(Admin::Views::Articles::Index.config.layout).to eq "app"
      end

      it "applies views config from the app" do
        Hanami.app.config.views.layout = "app_layout"

        prepare_app

        expect(Admin::Views::Articles::Index.config.layout).to eq "app_layout"
      end

      it "applies views config from the slice" do
        with_directory(@dir) do
          write "config/slices/admin.rb", <<~RUBY
            module Admin
              class Slice < Hanami::Slice
                config.views.layout = "slice_layout"
              end
            end
          RUBY
        end

        prepare_app

        expect(Admin::Views::Articles::Index.config.layout).to eq "slice_layout"
      end

      it "applies config from the slice base class" do
        prepare_app

        Admin::View.config.layout = "slice_base_class_layout"

        expect(Admin::Views::Articles::Index.config.layout).to eq "slice_base_class_layout"
      end

      it "prefers config from the slice base class over views config from the slice" do
        with_directory(@dir) do
          write "config/slices/admin.rb", <<~RUBY
            module Admin
              class Slice < Hanami::Slice
                config.views.layout = "slice_layout"
              end
            end
          RUBY
        end

        prepare_app

        Admin::View.config.layout = "slice_base_class_layout"

        expect(Admin::Views::Articles::Index.config.layout).to eq "slice_base_class_layout"
      end
    end
  end
end
