# frozen_string_literal: true

RSpec.describe "App view / Scope class", :app_integration do
  before do
    with_directory(@dir = make_tmp_directory) do
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

      before_app if respond_to?(:before_app)

      require "hanami/prepare"
    end
  end

  describe "app view" do
    let(:view_class) { TestApp::View }

    describe "no concrete app scope class defined" do
      it "generates an app scope class and configures it as the view's scope_class" do
        expect(view_class.config.scope_class).to be TestApp::Views::Scope
        expect(view_class.config.scope_class.superclass).to be Hanami::View::Scope
      end
    end

    describe "concrete app scope class defined" do
      def before_app
        write "app/views/scope.rb", <<~RUBY
          # auto_register: false

          module TestApp
            module Views
              class Scope < Hanami::View::Scope
                def self.concrete?
                  true
                end
              end
            end
          end
        RUBY
      end

      it "configures the app scope class as the view's scope_class" do
        expect(view_class.config.scope_class).to be TestApp::Views::Scope
        expect(view_class.config.scope_class).to be_concrete
      end
    end
  end

  describe "slice view" do
    let(:view_class) { Main::View }

    def before_app
      write "slices/main/view.rb", <<~RUBY
        # auto_register: false

        module Main
          class View < TestApp::View
          end
        end
      RUBY
    end

    describe "no concrete app scope class defined" do
      it "generates an app scope class and configures it as the view's scope_class" do
        expect(view_class.config.scope_class).to be Main::Views::Scope
        expect(view_class.config.scope_class.superclass).to be TestApp::Views::Scope
      end
    end

    describe "concrete app scope class defined" do
      def before_app
        super

        write "slices/main/views/scope.rb", <<~RUBY
          # auto_register: false

          module Main
            module Views
              class Scope < TestApp::Views::Scope
                def self.concrete?
                  true
                end
              end
            end
          end
        RUBY
      end

      it "configures the app scope class as the view's scope_class" do
        expect(view_class.config.scope_class).to eq Main::Views::Scope
        expect(view_class.config.scope_class).to be_concrete
      end
    end

    context "view not inheriting from app view, no concrete scope class" do
      def before_app
        write "slices/main/view.rb", <<~RUBY
          # auto_register: false

          module Main
            class View < Hanami::View
            end
          end
        RUBY
      end

      it "generates a slice scope class, inheriting from the app scope class, and configures it as the view's scope_class" do
        expect(view_class.config.scope_class).to be Main::Views::Scope
        expect(view_class.config.scope_class.superclass).to be TestApp::Views::Scope
      end
    end

    context "no app view class defined" do
      def before_app
        FileUtils.rm "app/view.rb"

        write "slices/main/view.rb", <<~RUBY
          # auto_register: false

          module Main
            class View < Hanami::View
            end
          end
        RUBY
      end

      it "generates a slice scope class, inheriting from Hanami::View::Scope, and configures it as the view's scope_class" do
        expect(view_class.config.scope_class).to be Main::Views::Scope
        expect(view_class.config.scope_class.superclass).to be Hanami::View::Scope
      end
    end
  end
end
