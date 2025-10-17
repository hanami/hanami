# frozen_string_literal: true

require "dry/inflector"

RSpec.describe "Deep nested resources", :app_integration do
  let(:router) { double("router") }
  let(:inflector) { Dry::Inflector.new }

  describe "NestedResourceContext functionality" do
    it "supports HTTP method delegation for custom routes" do
      routes_created = []

      # Mock the router to capture route creation
      allow(router).to receive(:get) do |path, **options|
        routes_created << { method: :get, path: path, options: options }
      end

      allow(router).to receive(:post) do |path, **options|
        routes_created << { method: :post, path: path, options: options }
      end

      # Create a nested resource context
      context = Hanami::Slice::Router::NestedResourceContext.new(router, inflector, "users")

      # Test custom routes within the context (relative paths should be scoped)
      context.get "stats", to: "posts.stats"
      context.post "bulk", to: "posts.bulk_create"

      # Verify custom routes are scoped correctly
      expect(routes_created).to include(
        { method: :get, path: "/users/:user_id/stats", options: { to: "posts.stats" } },
        { method: :post, path: "/users/:user_id/bulk", options: { to: "posts.bulk_create" } }
      )
    end

    it "supports deeper nesting with blocks" do
      nested_builder = double("nested_builder")
      allow(nested_builder).to receive(:build_routes)
      allow(nested_builder).to receive(:nested_path).and_return("users/:user_id/posts")
      allow(nested_builder).to receive(:nested_parent_name).and_return("post")

      allow(Hanami::Slice::Router::NestedResourceBuilder).to receive(:new).and_return(nested_builder)

      routes_created = []
      allow(router).to receive(:get) do |path, **options|
        routes_created << { method: :get, path: path, options: options }
      end

      context = Hanami::Slice::Router::NestedResourceContext.new(router, inflector, "users")

      # Test deeper nesting with custom routes
      context.resources :posts do
        get "extra", to: "comments.extra"
      end

      # Verify the nested builder was called correctly
      expect(Hanami::Slice::Router::NestedResourceBuilder).to have_received(:new).with(
        router: router,
        inflector: inflector,
        parent_path: "users",
        parent_name: "user",
        name: :posts,
        type: :plural,
        options: {}
      )

      # Verify custom route in nested context
      expect(routes_created).to include(
        { method: :get, path: "/users/:user_id/posts/:post_id/extra", options: { to: "comments.extra" } }
      )
    end

    it "maintains backward compatibility with existing nesting" do
      nested_builder = double("nested_builder")
      allow(nested_builder).to receive(:build_routes)
      allow(Hanami::Slice::Router::NestedResourceBuilder).to receive(:new).and_return(nested_builder)

      context = Hanami::Slice::Router::NestedResourceContext.new(router, inflector, "users")
      context.resources :posts

      # Verify the nested builder was called correctly (existing behavior)
      expect(Hanami::Slice::Router::NestedResourceBuilder).to have_received(:new).with(
        router: router,
        inflector: inflector,
        parent_path: "users",
        parent_name: "user",
        name: :posts,
        type: :plural,
        options: {}
      )
      expect(nested_builder).to have_received(:build_routes)
    end
  end

  describe "NestedResourceBuilder enhancements" do
    it "provides nested_path and nested_parent_name for deeper nesting" do
      builder = Hanami::Slice::Router::NestedResourceBuilder.new(
        router: router,
        inflector: inflector,
        parent_path: "users",
        parent_name: "user",
        name: :posts,
        type: :plural,
        options: {}
      )

      expect(builder.nested_path).to eq "users/:user_id/posts"
      expect(builder.nested_parent_name).to eq "post"
    end

    it "handles singular resources correctly" do
      builder = Hanami::Slice::Router::NestedResourceBuilder.new(
        router: router,
        inflector: inflector,
        parent_path: "users",
        parent_name: "user",
        name: :profile,
        type: :singular,
        options: {}
      )

      expect(builder.nested_path).to eq "users/:user_id/profile"
      expect(builder.nested_parent_name).to eq "profile"
    end
  end
end
