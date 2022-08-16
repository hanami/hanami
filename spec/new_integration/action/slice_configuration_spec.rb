# frozen_string_literal: true

RSpec.describe "App action / Slice configuration", :app_integration do
  before do
    with_directory(@dir = make_tmp_directory) do
      write "config/app.rb", <<~'RUBY'
        require "hanami"

        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "app/action.rb", <<~'RUBY'
        require "hanami/action"

        module TestApp
          class Action < Hanami::Action
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
      it "applies default actions config from the app", :aggregate_failures do
        prepare_app

        expect(TestApp::Action.config.default_request_format).to eq :html
        expect(TestApp::Action.config.default_response_format).to eq :html
      end

      it "applies actions config from the app" do
        Hanami.app.config.actions.default_response_format = :json

        prepare_app

        expect(TestApp::Action.config.default_response_format).to eq :json
      end

      it "does not override config in the base class" do
        Hanami.app.config.actions.default_response_format = :csv

        prepare_app

        TestApp::Action.config.default_response_format = :json
      end
    end

    describe "subclass in app" do
      before do
        with_directory(@dir) do
          write "app/actions/articles/index.rb", <<~'RUBY'
            module TestApp
              module Actions
                module Articles
                  class Index < TestApp::Action
                  end
                end
              end
            end
          RUBY
        end
      end

      it "applies default actions config from the app", :aggregate_failures do
        prepare_app

        expect(TestApp::Actions::Articles::Index.config.default_request_format).to eq :html
        expect(TestApp::Actions::Articles::Index.config.default_response_format).to eq :html
      end

      it "applies actions config from the app" do
        Hanami.app.config.actions.default_response_format = :json

        prepare_app

        expect(TestApp::Actions::Articles::Index.config.default_response_format).to eq :json
      end

      it "applies config from the base class" do
        prepare_app

        TestApp::Action.config.default_response_format = :json

        expect(TestApp::Actions::Articles::Index.config.default_response_format).to eq :json
      end
    end

    describe "subclass in slice" do
      before do
        with_directory(@dir) do
          write "slices/admin/actions/articles/index.rb", <<~'RUBY'
            module Admin
              module Actions
                module Articles
                  class Index < TestApp::Action
                  end
                end
              end
            end
          RUBY
        end
      end

      it "applies default actions config from the app", :aggregate_failures do
        prepare_app

        expect(Admin::Actions::Articles::Index.config.default_request_format).to eq :html
        expect(Admin::Actions::Articles::Index.config.default_response_format).to eq :html
      end

      it "applies actions config from the app" do
        Hanami.app.config.actions.default_response_format = :json

        prepare_app

        expect(Admin::Actions::Articles::Index.config.default_response_format).to eq :json
      end

      it "applies config from the base class" do
        prepare_app

        TestApp::Action.config.default_response_format = :json

        expect(Admin::Actions::Articles::Index.config.default_response_format).to eq :json
      end
    end
  end

  describe "inheriting from a slice-level base class, in turn inheriting from an app-level base class" do
    before do
      with_directory(@dir) do
        write "slices/admin/action.rb", <<~'RUBY'
          module Admin
            class Action < TestApp::Action
            end
          end
        RUBY
      end
    end

    describe "slice-level base class" do
      it "applies default actions config from the app", :aggregate_failures do
        prepare_app

        expect(Admin::Action.config.default_request_format).to eq :html
        expect(Admin::Action.config.default_response_format).to eq :html
      end

      it "applies actions config from the app" do
        Hanami.app.config.actions.default_response_format = :json

        prepare_app

        expect(Admin::Action.config.default_response_format).to eq :json
      end

      it "applies config from the app base class" do
        prepare_app

        TestApp::Action.config.default_response_format = :json

        expect(Admin::Action.config.default_response_format).to eq :json
      end

      context "slice actions config present" do
        before do
          with_directory(@dir) do
            write "config/slices/admin.rb", <<~'RUBY'
              module Admin
                class Slice < Hanami::Slice
                  config.actions.default_response_format = :csv
                end
              end
            RUBY
          end
        end

        it "applies actions config from the slice" do
          prepare_app

          expect(Admin::Action.config.default_response_format).to eq :csv
        end

        it "prefers actions config from the slice over config from the app-level base class" do
          prepare_app

          TestApp::Action.config.default_response_format = :json

          expect(Admin::Action.config.default_response_format).to eq :csv
        end

        it "prefers config from the base class over actions config from the slice" do
          prepare_app

          TestApp::Action.config.default_response_format = :csv
          Admin::Action.config.default_response_format = :json

          expect(Admin::Action.config.default_response_format).to eq :json
        end
      end
    end

    describe "subclass in slice" do
      before do
        with_directory(@dir) do
          write "slices/admin/actions/articles/index.rb", <<~'RUBY'
            module Admin
              module Actions
                module Articles
                  class Index < Admin::Action
                  end
                end
              end
            end
          RUBY
        end
      end

      it "applies default actions config from the app", :aggregate_failures do
        prepare_app

        expect(Admin::Actions::Articles::Index.config.default_request_format).to eq :html
        expect(Admin::Actions::Articles::Index.config.default_response_format).to eq :html
      end

      it "applies actions config from the app" do
        Hanami.app.config.actions.default_response_format = :json

        prepare_app

        expect(Admin::Actions::Articles::Index.config.default_response_format).to eq :json
      end

      it "applies actions config from the slice" do
        with_directory(@dir) do
          write "config/slices/admin.rb", <<~'RUBY'
            module Admin
              class Slice < Hanami::Slice
                config.actions.default_response_format = :json
              end
            end
          RUBY
        end

        prepare_app

        expect(Admin::Actions::Articles::Index.config.default_response_format).to eq :json
      end

      it "applies config from the slice base class" do
        prepare_app

        Admin::Action.config.default_response_format = :json

        expect(Admin::Actions::Articles::Index.config.default_response_format).to eq :json
      end

      it "prefers config from the slice base class over actions config from the slice" do
        with_directory(@dir) do
          write "config/slices/admin.rb", <<~'RUBY'
            module Admin
              class Slice < Hanami::Slice
                config.actions.default_response_format = :csv
              end
            end
          RUBY
        end

        prepare_app

        Admin::Action.config.default_response_format = :json

        expect(Admin::Actions::Articles::Index.config.default_response_format).to eq :json
      end
    end
  end
end
