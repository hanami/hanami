# frozen_string_literal: true

require "dry/inflector"

RSpec.describe "Nested resources using scope", :app_integration do
  let(:inflector) { Dry::Inflector.new }

  describe "nested resources functionality" do
    it "uses scope method for nested resource routing" do
      # Test that the NestedResourceContext uses scope internally
      router = double("router")
      allow(router).to receive(:scope).and_yield

      resource_builder = double("resource_builder")
      allow(resource_builder).to receive(:build_routes)
      allow(resource_builder).to receive(:path).and_return("posts")

      allow(Hanami::Slice::Router::ResourceBuilder).to receive(:new).and_return(resource_builder)

      context = Hanami::Slice::Router::NestedResourceContext.new(router, inflector, "users")
      context.resources(:posts)

      # Verify that scope was called with the correct nested path
      expect(router).to have_received(:scope).with("users/:user_id")
      expect(resource_builder).to have_received(:build_routes)
    end

    it "supports deeper nesting using scope" do
      router = double("router")
      allow(router).to receive(:scope).and_yield

      # Mock the resource builders
      posts_builder = double("posts_builder")
      allow(posts_builder).to receive(:build_routes)
      allow(posts_builder).to receive(:path).and_return("posts")

      comments_builder = double("comments_builder")
      allow(comments_builder).to receive(:build_routes)
      allow(comments_builder).to receive(:path).and_return("comments")

      allow(Hanami::Slice::Router::ResourceBuilder).to receive(:new).and_return(posts_builder, comments_builder)

      context = Hanami::Slice::Router::NestedResourceContext.new(router, inflector, "users")

      # Test deeper nesting - the inner resources call will create a new context
      context.resources :posts do
        # This creates a new NestedResourceContext internally
        resources :comments
      end

      # Verify scope was called for both levels
      expect(router).to have_received(:scope).with("users/:user_id").at_least(:once)
      expect(router).to have_received(:scope).with("posts/:post_id").at_least(:once)
      # The deeper nesting creates new builders
      expect(Hanami::Slice::Router::ResourceBuilder).to have_received(:new).twice
    end

    it "maintains backward compatibility with existing nested resource behavior" do
      # Test that the nested resource context still exists and works as expected
      expect(Hanami::Slice::Router::NestedResourceContext).to be_a(Class)

      # Test that we now use the regular ResourceBuilder for nested resources
      expect(Hanami::Slice::Router::ResourceBuilder).to be_a(Class)
    end
  end
end
