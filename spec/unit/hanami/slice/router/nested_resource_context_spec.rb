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
    let(:nested_builder) { double("nested_builder") }

    before do
      allow(Hanami::Slice::Router::NestedResourceBuilder).to receive(:new).and_return(nested_builder)
      allow(nested_builder).to receive(:build_routes)
    end

    it "creates a NestedResourceBuilder for plural resources" do
      expect(Hanami::Slice::Router::NestedResourceBuilder).to receive(:new).with(
        router: router,
        inflector: inflector,
        parent_path: parent_path,
        parent_name: "user",
        name: :posts,
        type: :plural,
        options: { only: [:index] }
      )

      context.resources(:posts, only: [:index])
    end

    it "calls build_routes on the nested builder" do
      expect(nested_builder).to receive(:build_routes)
      context.resources(:posts)
    end
  end

  describe "#resource" do
    let(:nested_builder) { double("nested_builder") }

    before do
      allow(Hanami::Slice::Router::NestedResourceBuilder).to receive(:new).and_return(nested_builder)
      allow(nested_builder).to receive(:build_routes)
    end

    it "creates a NestedResourceBuilder for singular resources" do
      expect(Hanami::Slice::Router::NestedResourceBuilder).to receive(:new).with(
        router: router,
        inflector: inflector,
        parent_path: parent_path,
        parent_name: "user",
        name: :profile,
        type: :singular,
        options: { except: [:destroy] }
      )

      context.resource(:profile, except: [:destroy])
    end

    it "calls build_routes on the nested builder" do
      expect(nested_builder).to receive(:build_routes)
      context.resource(:profile)
    end
  end

  describe "private methods" do
    describe "#build_nested_resource" do
      let(:nested_builder) { double("nested_builder") }

      before do
        allow(Hanami::Slice::Router::NestedResourceBuilder).to receive(:new).and_return(nested_builder)
        allow(nested_builder).to receive(:build_routes)
      end

      it "creates and builds nested resource" do
        expect(Hanami::Slice::Router::NestedResourceBuilder).to receive(:new).with(
          router: router,
          inflector: inflector,
          parent_path: parent_path,
          parent_name: "user",
          name: :comments,
          type: :plural,
          options: { only: [:index, :show] }
        )
        expect(nested_builder).to receive(:build_routes)

        context.send(:build_nested_resource, :comments, :plural, { only: [:index, :show] })
      end
    end
  end
end
