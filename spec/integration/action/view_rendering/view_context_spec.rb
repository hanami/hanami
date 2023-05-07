# frozen_string_literal: true

RSpec.describe "App action / View rendering / View context", :app_integration do
  subject(:context) {
    # We capture the context during rendering via our view spies; see the view classes below
    action.call("REQUEST_METHOD" => "GET", "QUERY_STRING" => "/mock_request")
    action.view.called_with[:context]
  }

  before do
    with_directory(make_tmp_directory) do
      write "config/app.rb", <<~RUBY
        module TestApp
          class App < Hanami::App
          end
        end
      RUBY

      write "app/action.rb", <<~RUBY
        # auto_register: false

        require "hanami/view"

        module TestApp
          class Action < Hanami::Action
          end
        end
      RUBY

      before_prepare if respond_to?(:before_prepare)
      require "hanami/prepare"
    end
  end

  describe "app action" do
    let(:action) { TestApp::App["actions.posts.show"] }

    def before_prepare
      write "app/actions/posts/show.rb", <<~RUBY
        module TestApp
          module Actions
            module Posts
              class Show < TestApp::Action
              end
            end
          end
        end
      RUBY

      # Custom view class as a spy for `#call` args
      write "app/views/posts/show.rb", <<~RUBY
        module TestApp
          module Views
            module Posts
              class Show
                attr_reader :called_with

                def call(**args)
                  @called_with = args
                  ""
                end
              end
            end
          end
        end
      RUBY
    end

    context "no context class defined" do
      it "defines and uses a context class" do
        expect(context).to be_an_instance_of TestApp::Views::Context
        expect(context.class).to be < Hanami::View::Context
      end

      it "includes the request" do
        expect(context.request).to be_an_instance_of Hanami::Action::Request
        expect(context.request.env["QUERY_STRING"]).to eq "/mock_request"
      end
    end

    context "context class defined" do
      def before_prepare
        super()

        write "app/views/context.rb", <<~RUBY
          # auto_register: false

          module TestApp
            module Views
              class Context < Hanami::View::Context
                def concrete_app_context?
                  true
                end
              end
            end
          end
        RUBY
      end

      it "uses the defined context class" do
        expect(context).to be_an_instance_of TestApp::Views::Context
        expect(context).to be_a_concrete_app_context
      end
    end

    context "hanami-view not bundled" do
      before do
        allow(Hanami).to receive(:bundled?).and_call_original
        expect(Hanami).to receive(:bundled?).with("hanami-view").and_return false
      end

      it "does not provide a context" do
        expect(context).to be nil
      end

      context "context class defined" do
        def before_prepare
          super()

          write "app/views/context.rb", <<~RUBY
            module TestApp
              module Views
                class Context
                  def initialize(**)
                  end

                  def with(**)
                    self
                  end

                  def concrete_app_context?
                    true
                  end
                end
              end
            end
          RUBY
        end

        it "uses the defined context class" do
          expect(context).to be_an_instance_of TestApp::Views::Context
          expect(context).to be_a_concrete_app_context
        end
      end
    end
  end

  describe "slice action" do
    let(:action) { Main::Slice["actions.posts.show"] }

    def before_prepare
      write "slices/main/action.rb", <<~RUBY
        module Main
          class Action < TestApp::Action
          end
        end
      RUBY

      write "slices/main/actions/posts/show.rb", <<~RUBY
        module Main
          module Actions
            module Posts
              class Show < Main::Action
              end
            end
          end
        end
      RUBY

      # Custom view class as a spy for `#call` args
      write "slices/main/views/posts/show.rb", <<~RUBY
        module Main
          module Views
            module Posts
              class Show
                attr_reader :called_with

                def call(**args)
                  @called_with = args
                  ""
                end
              end
            end
          end
        end
      RUBY
    end

    context "no context class defined" do
      it "defines and uses a context class" do
        expect(context).to be_an_instance_of Main::Views::Context
        expect(context.class).to be < Hanami::View::Context
      end
    end

    context "context class defined" do
      def before_prepare
        super()

        write "slices/main/views/context.rb", <<~RUBY
          # auto_register: false

          module Main
            module Views
              class Context < Hanami::View::Context
                def concrete_slice_context?
                  true
                end
              end
            end
          end
        RUBY
      end

      it "uses the defined context class" do
        expect(context).to be_an_instance_of Main::Views::Context
        expect(context).to be_a_concrete_slice_context
      end
    end
  end
end
