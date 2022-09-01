# frozen_string_literal: true

RSpec.describe "App action / View integration", :app_integration do
  before do
    module TestApp
      class App < Hanami::App
      end
    end

    Hanami.app.instance_eval(&app_hook) if respond_to?(:app_hook)
    Hanami.app.prepare

    module TestApp
      class Action < Hanami::Action; end
    end

    module TestApp
      module Actions
        module Articles
          class Index < TestApp::Action; end
        end
      end
    end
  end

  let(:action_class) { TestApp::Actions::Articles::Index }
  subject(:action) { action_class.new(**action_args) }
  let(:action_args) { {} }

  describe "#view_context" do
    subject(:view_context) { action.view_context }

    context "Explicitly injected view context" do
      let(:view_context) { double(:view_context) }
      let(:action_args) { {view_context: view_context} }

      it "returns the injected object" do
        is_expected.to eql view_context
      end
    end

    context "No view context registered" do
      it "is nil" do
        is_expected.to be_nil
      end
    end

    context "Default view context identifier" do
      context "View context registered in slice" do
        before do
          TestApp::App.register "views.context", slice_view_context
        end

        let(:slice_view_context) { double(:slice_view_context) }

        it "is the slice's view context" do
          is_expected.to eql slice_view_context
        end
      end

      context "View context registered in app" do
        before do
          Hanami.app.register "views.context", app_view_context
        end

        let(:app_view_context) { double(:app_view_context) }

        it "is the apps's view context" do
          is_expected.to eql app_view_context
        end
      end
    end

    context "custom view context identifier" do
      let(:app_hook) {
        proc do |app|
          app.config.actions.view_context_identifier = "view.custom_context"
        end
      }

      before do
        TestApp::App.register "view.custom_context", custom_view_context
      end

      let(:custom_view_context) { double(:custom_view_context) }

      it "is the context registered with the custom identifier" do
        is_expected.to eql custom_view_context
      end
    end
  end

  describe "#view_options" do
    subject(:view_options) { action.send(:view_options, req, res) }
    let(:req) { double(:req) }
    let(:res) { double(:res) }

    context "without view context" do
      it "is an empty hash" do
        is_expected.to eq({})
      end
    end

    context "with view context" do
      let(:initial_view_context) { double(:initial_view_context) }
      let(:action_args) { {view_context: initial_view_context} }

      context "default #view_context_options" do
        let(:request_view_context) { double(:request_view_context) }

        before do
          allow(initial_view_context).to receive(:with).with(
            request: req,
            response: res,
          ) { request_view_context }
        end

        it "is the view context with the request and response provided" do
          is_expected.to eq(context: request_view_context)
        end
      end

      context "custom #view_context_options" do
        let(:custom_view_context) { double(:custom_view_context)}

        before do
          action_class.class_eval do
            def view_context_options(req, res)
              {custom_option: "custom option"}
            end
          end

          allow(initial_view_context).to receive(:with).with(
            custom_option: "custom option"
          ) { custom_view_context }
        end

        it "is the view context with the custom options provided" do
          is_expected.to eq(context: custom_view_context)
        end
      end

      context "specialized method (calling super) defined in action class" do
        let(:request_view_context) { double(:request_view_context) }

        before do
          allow(initial_view_context).to receive(:with).with(
            request: req,
            response: res,
          ) { request_view_context }

          action_class.class_eval do
            def view_options(req, res)
              super.merge(extra_option: "extra option")
            end
          end
        end

        it "includes the options provided by the specialized method" do
          is_expected.to eq(context: request_view_context, extra_option: "extra option")
        end
      end
    end
  end
end
