# frozen_string_literal: true

RSpec.describe "App view / Config / Default context", :app_integration do
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

      before_prepare if respond_to?(:before_prepare)
      require "hanami/prepare"
    end
  end

  subject(:default_context) { view_class.config.default_context }

  describe "app view" do
    let(:view_class) { TestApp::View }

    describe "no concrete context class defined" do
      it "generates an app context class and configures it as the view's default_context" do
        expect(default_context).to be_an_instance_of TestApp::Views::Context
        expect(default_context.class.superclass).to be Hanami::View::Context
      end
    end

    describe "concrete context class defined" do
      def before_prepare
        write "app/views/context.rb", <<~RUBY
          # auto_register: false

          module TestApp
            module Views
              class Context < Hanami::View::Context
                def concrete?
                  true
                end
              end
            end
          end
        RUBY
      end

      it "configures the app scope class as the view's scope_class" do
        expect(default_context).to be_an_instance_of TestApp::Views::Context
        expect(default_context).to be_concrete
      end
    end
  end

  describe "slice view" do
    let(:view_class) { Main::View }

    def before_prepare
      write "slices/main/view.rb", <<~RUBY
        # auto_register: false

        module Main
          class View < TestApp::View
          end
        end
      RUBY
    end

    describe "no concrete slice context class defined" do
      it "generates an app context class and configures it as the view's default_context" do
        expect(default_context).to be_an_instance_of Main::Views::Context
        expect(default_context.class.superclass).to be TestApp::Views::Context
      end
    end

    describe "concrete slice context class defined" do
      def before_prepare
        super

        write "slices/main/views/context.rb", <<~RUBY
          # auto_register: false

          module Main
            module Views
              class Context < Hanami::View::Context
                def concrete?
                  true
                end
              end
            end
          end
        RUBY
      end

      it "configures the slice context as the view's default_context" do
        expect(default_context).to be_an_instance_of Main::Views::Context
        expect(default_context).to be_concrete
      end
    end

    describe "view not inheriting from app view, no concrete context class defined" do
      def before_prepare
        write "slices/main/view.rb", <<~RUBY
          # auto_register: false

          module Main
            class View < Hanami::View
            end
          end
        RUBY
      end

      it "generates a slice context class, inheriting from the app context class, and configures it as the view's default_context" do
        expect(default_context).to be_an_instance_of Main::Views::Context
        expect(default_context.class.superclass).to be TestApp::Views::Context
      end
    end

    describe "no app view class defined" do
      def before_prepare
        FileUtils.rm "app/view.rb"

        write "slices/main/view.rb", <<~RUBY
          # auto_register: false

          module Main
            class View < Hanami::View
            end
          end
        RUBY
      end

      it "generates a slice context class, inheriting from the app context class, and configures it as the view's default_context" do
        expect(default_context).to be_an_instance_of Main::Views::Context
        expect(default_context.class.superclass).to be Hanami::View::Context
      end
    end
  end
end
