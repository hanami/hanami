# frozen_string_literal: true

require "hanami/application"
require "hanami/slice_configurable"

RSpec.describe Hanami::SliceConfigurable, :application_integration do
  before do
    module TestApp
      class Application < Hanami::Application
        register_slice :main
        register_slice :admin
      end

      class BaseClass
        extend Hanami::SliceConfigurable

        def self.configure_for_slice(slice)
          traces << slice
        end

        def self.traces
          @traces ||= []
        end

        def self.inherited(subclass)
          subclass.instance_variable_set(:@traces, traces.dup)
          super
        end
      end
    end

    Hanami.application.prepare
  end

  context "subclass inside slice namespace" do
    before do
      module Main
        class MySubclass < TestApp::BaseClass; end
      end
    end

    subject(:subclass) { Main::MySubclass }

    it "calls `configure_for_slice` with the slice" do
      expect(subclass.traces).to eq [Main::Slice]
    end

    context "further subclass, within same slice" do
      before do
        module Main
          class MySubSubclass < Main::MySubclass; end
        end
      end

      subject(:subclass) { Main::MySubSubclass }

      it "does not call `configure_for_slice` again for the same slice" do
        expect(subclass.traces).to eq [Main::Slice]
      end
    end

    context "further subclass, within another slice namespace" do
      before do
        module Admin
          class MySubSubclass < Main::MySubclass; end
        end
      end

      subject(:subclass) { Admin::MySubSubclass }

      it "calls `configure_for_slice` with the other slice" do
        expect(subclass.traces).to eq [Main::Slice, Admin::Slice]
      end
    end
  end

  context "class inside application" do
    before do
      module TestApp
        class MySubclass < TestApp::BaseClass; end
      end
    end

    subject(:subclass) { TestApp::MySubclass }

    it "calls `configure_for_slice` with the application instance" do
      expect(subclass.traces).to eq [TestApp::Application]
    end

    context "further subclass, within another slice namespace" do
      before do
        module Main
          class MySubSubclass < TestApp::MySubclass; end
        end
      end

      subject(:subclass) { Main::MySubSubclass }

      it "calls `configure_for_slice` with the other slice" do
        expect(subclass.traces).to eq [TestApp::Application, Main::Slice]
      end
    end
  end
end
