# frozen_string_literal: true

require "dry/inflector"

RSpec.describe Hanami::Slice::Router::NestedResourceContext do
  let(:router) { double("router") }
  let(:inflector) { Dry::Inflector.new }
  let(:parent_path) { "users" }

  subject(:context) do
    described_class.new(router, inflector, parent_path)
  end

  describe "#initialize" do
    it "sets router and parent_path" do
      expect(context.instance_variable_get(:@router)).to eq router
      expect(context.instance_variable_get(:@parent_path)).to eq parent_path
    end
  end

  describe "#resources" do
    let(:resource_builder) { double("resource_builder") }

    before do
      allow(Hanami::Slice::Router::ResourceBuilder).to receive(:new).and_return(resource_builder)
      allow(resource_builder).to receive(:build_routes)
      allow(resource_builder).to receive(:path).and_return("posts")
      allow(router).to receive(:scope).and_yield
    end

    it "creates a ResourceBuilder for plural resources" do
      expect(Hanami::Slice::Router::ResourceBuilder).to receive(:new).with(
        router: router,
        inflector: inflector,
        name: :posts,
        type: :plural,
        options: { only: [:index] }
      )

      context.resources(:posts, only: [:index])
    end

    it "calls build_routes on the resource builder" do
      expect(resource_builder).to receive(:build_routes)
      context.resources(:posts)
    end

    it "uses scope with correct nested path" do
      expect(router).to receive(:scope).with("users/:user_id")
      context.resources(:posts)
    end
  end

  describe "#resource" do
    let(:resource_builder) { double("resource_builder") }

    before do
      allow(Hanami::Slice::Router::ResourceBuilder).to receive(:new).and_return(resource_builder)
      allow(resource_builder).to receive(:build_routes)
      allow(resource_builder).to receive(:path).and_return("profile")
      allow(router).to receive(:scope).and_yield
    end

    it "creates a ResourceBuilder for singular resources" do
      expect(Hanami::Slice::Router::ResourceBuilder).to receive(:new).with(
        router: router,
        inflector: inflector,
        name: :profile,
        type: :singular,
        options: { except: [:destroy] }
      )

      context.resource(:profile, except: [:destroy])
    end

    it "calls build_routes on the resource builder" do
      expect(resource_builder).to receive(:build_routes)
      context.resource(:profile)
    end

    it "uses scope with correct nested path" do
      expect(router).to receive(:scope).with("users/:user_id")
      context.resource(:profile)
    end
  end
end
