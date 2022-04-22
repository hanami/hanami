# frozen_string_literal: true

require "hanami/application/action"

RSpec.describe "Application action / View rendering / Paired view inference", :application_integration do
  before do
    module TestApp
      class Application < Hanami::Application
        register_slice :main
      end
    end

    Hanami.application.prepare

    module Main
      module Action
        class Base < Hanami::Application::Action; end
      end
    end
  end

  let(:action) { action_class.new }

  describe "Ordinary action" do
    before do
      module Main
        module Actions
          module Articles
            class Index < Main::Action::Base; end
          end
        end
      end
    end

    let(:action_class) { Main::Actions::Articles::Index }

    context "Paired view exists" do
      before do
        Main::Slice.register "views.articles.index", view
      end

      let(:view) { double(:view) }

      it "auto-injects a paired view from a matching container identifier" do
        expect(action.view).to be view
      end

      context "Another view explicitly auto-injected" do
        before do
          module Main
            module Actions
              module Articles
                class Index < Main::Action::Base
                  include Deps[view: "views.articles.custom"]
                end
              end
            end
          end

          Main::Slice.register "views.articles.custom", explicit_view
        end

        let(:action_class) { Main::Actions::Articles::Index }
        let(:explicit_view) { double(:explicit_view) }

        it "respects the explicitly auto-injected view" do
          expect(action.view).to be explicit_view
        end
      end
    end

    context "No paired view exists" do
      it "does not auto-inject any view" do
        expect(action.view).to be_nil
      end
    end
  end

  describe "RESTful action" do
    before do
      module Main
        module Actions
          module Articles
            class Create < Main::Action::Base; end
          end
        end
      end
    end

    let(:action_class) { Main::Actions::Articles::Create }
    let(:direct_paired_view) { double(:direct_paired_view) }
    let(:alternative_paired_view) { double(:alternative_paired_view) }

    context "Direct paired view exists" do
      before do
        Main::Slice.register "views.articles.create", direct_paired_view
        Main::Slice.register "views.articles.new", alternative_paired_view
      end

      it "auto-injects the directly paired view" do
        expect(action.view).to be direct_paired_view
      end
    end

    context "Alternative paired view exists" do
      before do
        Main::Slice.register "views.articles.new", alternative_paired_view
      end

      it "auto-injects the alternative paired view" do
        expect(action.view).to be alternative_paired_view
      end
    end
  end
end
