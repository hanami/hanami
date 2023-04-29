# frozen_string_literal: true

require "hanami"

RSpec.describe "App view / Config / Scope namespace", :app_integration do
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

      before_prepare if respond_to?(:before_prepare)
      require "hanami/prepare"
    end
  end

  subject(:scope_namespace) { view_class.config.scope_namespace }

  describe "app view" do
    let(:view_class) { TestApp::View }

    describe "no scope namespace defined" do
      it "is nil" do
        expect(scope_namespace).to be nil
      end
    end

    describe "scope namespace defined" do
      def before_prepare
        write "app/views/scopes/player.rb", <<~RUBY
          module TestApp
            module Views
              module Scopes
                class Player < Hanami::View::Scope
                end
              end
            end
          end
        RUBY
      end

      it "is the Views::Scopes namespace within the app" do
        expect(scope_namespace).to eq TestApp::Views::Scopes
      end
    end
  end

  describe "slice view" do
    def before_prepare
      write "slices/main/view.rb", <<~RUBY
        # auto_register: false

        module Main
          class View < TestApp::View
          end
        end
      RUBY
    end

    let(:view_class) { Main::View }

    describe "no scope namespace defined" do
      it "is nil" do
        expect(scope_namespace).to be nil
      end
    end

    describe "scope namespace defined" do
      def before_prepare
        super

        write "slices/main/views/scopes/player.rb", <<~RUBY
          module Main
            module Views
              module Scopes
                class Player < Hanami::View::Scope
                end
              end
            end
          end
        RUBY
      end

      it "is the Views::Scopes namespace within the slice" do
        expect(scope_namespace).to eq Main::Views::Scopes
      end
    end
  end
end
