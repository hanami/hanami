# frozen_string_literal: true

require "dry/inflector"

RSpec.describe Hanami::Slice::Router::NestedResourceBuilder do
  let(:router) { double("router") }
  let(:inflector) { Dry::Inflector.new }
  let(:parent_path) { "users" }
  let(:name) { :posts }
  let(:type) { :plural }
  let(:options) { {} }

  subject(:builder) do
    described_class.new(
      router: router,
      inflector: inflector,
      parent_path: parent_path,
      name: name,
      type: type,
      options: options
    )
  end

  describe "#initialize" do
    it "inherits from ResourceBuilder" do
      expect(builder).to be_a(Hanami::Slice::Router::ResourceBuilder)
    end

    it "sets parent_path" do
      expect(builder.parent_path).to eq "users"
    end

    it "sets parent_name as singularized parent_path" do
      expect(builder.parent_name).to eq "user"
    end

    context "with singular parent" do
      let(:parent_path) { "profile" }

      it "uses parent_path as parent_name for singular parents" do
        expect(builder.parent_name).to eq "profile"
      end
    end
  end

  describe "private methods" do
    describe "#build_route_path" do
      it "builds nested route path with parent id parameter" do
        expect(builder.send(:build_route_path, "")).to eq "/users/:user_id/posts"
      end

      it "builds nested route path with suffix" do
        expect(builder.send(:build_route_path, "/new")).to eq "/users/:user_id/posts/new"
      end

      it "builds nested route path with id parameter" do
        expect(builder.send(:build_route_path, "/:id")).to eq "/users/:user_id/posts/:id"
      end

      context "with singular nested resource" do
        let(:type) { :singular }
        let(:name) { :profile }

        it "removes :id from paths for singular resources" do
          expect(builder.send(:build_route_path, "/:id/edit")).to eq "/users/:user_id/profile/edit"
        end

        it "builds correct path without id" do
          expect(builder.send(:build_route_path, "")).to eq "/users/:user_id/profile"
        end
      end
    end

    describe "#build_route_name" do
      it "builds nested route name for index action" do
        expect(builder.send(:build_route_name, :index, "")).to eq "user_posts"
      end

      it "builds nested route name for other actions" do
        expect(builder.send(:build_route_name, :show, "")).to eq "user_post"
      end

      it "builds nested route name with prefix" do
        expect(builder.send(:build_route_name, :show, "edit_")).to eq "edit_user_post"
      end

      context "with singular nested resource" do
        let(:type) { :singular }
        let(:name) { :profile }

        it "builds correct nested route name for singular resource" do
          expect(builder.send(:build_route_name, :show, "")).to eq "user_profile"
        end

        it "builds correct nested route name with prefix for singular resource" do
          expect(builder.send(:build_route_name, :show, "edit_")).to eq "edit_user_profile"
        end
      end

      context "with custom route name" do
        let(:options) { { as: "article" } }

        it "uses custom route name in nested context" do
          expect(builder.send(:build_route_name, :show, "")).to eq "user_article"
        end
      end
    end
  end
end
