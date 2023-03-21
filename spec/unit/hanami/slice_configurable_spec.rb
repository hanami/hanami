# frozen_string_literal: true

require "hanami/app"
require "hanami/slice_configurable"

RSpec.describe Hanami::SliceConfigurable, :app_integration do
  before do
    module TestApp
      class App < Hanami::App
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

      it "does not call `configure_for_slice` again" do
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

  context "subclass inside slice with name overlapping another slice" do
    let(:app_modules) { super() << :ExternalAdmin }

    before do
      TestApp::App.register_slice :external_admin

      module ExternalAdmin
        class MySubclass < TestApp::BaseClass; end
      end
    end

    subject(:subclass) { ExternalAdmin::MySubclass }

    it "calls `configure_for_slice` with the correct matching slice" do
      expect(subclass.traces).to eq [ExternalAdmin::Slice]
    end
  end

  context "class inside app" do
    before do
      module TestApp
        class MySubclass < TestApp::BaseClass; end
      end
    end

    subject(:subclass) { TestApp::MySubclass }

    it "calls `configure_for_slice` with the app instance" do
      expect(subclass.traces).to eq [TestApp::App]
    end

    context "further subclass, within another slice namespace" do
      before do
        module Main
          class MySubSubclass < TestApp::MySubclass; end
        end
      end

      subject(:subclass) { Main::MySubSubclass }

      it "calls `configure_for_slice` with the other slice" do
        expect(subclass.traces).to eq [TestApp::App, Main::Slice]
      end
    end
  end

  context "subclass inside nested slice namespace" do
    before do
      module Main
        class Slice
          register_slice :nested
        end

        module Nested
          class MySubclass < TestApp::BaseClass
          end
        end
      end
    end

    subject(:subclass) { Main::Nested::MySubclass }

    it "calls `configure_for_slice` with the nested slice" do
      expect(subclass.traces).to eq [Main::Nested::Slice]
    end
  end
end
