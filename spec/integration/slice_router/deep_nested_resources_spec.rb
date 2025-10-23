# frozen_string_literal: true

require "dry/inflector"

RSpec.describe "Nested resources using scope", :app_integration do
  let(:inflector) { Dry::Inflector.new }

  describe "nested resources functionality" do
    it "uses scope method for nested resource routing" do
      # Test that the NestedResourceContext uses scope internally
      router = double("router")
      allow(router).to receive(:scope).and_yield
      
      nested_builder = double("nested_builder")
      allow(nested_builder).to receive(:build_routes)
      allow(nested_builder).to receive(:path).and_return("posts")
      
      allow(Hanami::Slice::Router::NestedResourceBuilder).to receive(:new).and_return(nested_builder)
      
      context = Hanami::Slice::Router::NestedResourceContext.new(router, inflector, "users")
      context.resources(:posts)
      
      # Verify that scope was called with the correct nested path
      expect(router).to have_received(:scope).with("users/:user_id")
      expect(nested_builder).to have_received(:build_routes)
    end

    it "supports deeper nesting using scope" do
      router = double("router")
      allow(router).to receive(:scope).and_yield
      
      # Mock the nested builders
      posts_builder = double("posts_builder")
      allow(posts_builder).to receive(:build_routes)
      allow(posts_builder).to receive(:path).and_return("posts")
      
      comments_builder = double("comments_builder")
      allow(comments_builder).to receive(:build_routes)
      allow(comments_builder).to receive(:path).and_return("comments")
      
      allow(Hanami::Slice::Router::NestedResourceBuilder).to receive(:new).and_return(posts_builder, comments_builder)
      
      context = Hanami::Slice::Router::NestedResourceContext.new(router, inflector, "users")
      
      # Test deeper nesting - the inner resources call will create a new context
      context.resources :posts do
        # This creates a new NestedResourceContext internally
        resources :comments
      end
      
      # Verify scope was called for the first level
      expect(router).to have_received(:scope).with("users/:user_id").at_least(:once)
      # The deeper nesting creates a new context, so we verify the builders were created
      expect(Hanami::Slice::Router::NestedResourceBuilder).to have_received(:new).twice
    end

    it "maintains backward compatibility with existing nested resource behavior" do
      # Test that the nested resource classes still exist and work as expected
      expect(Hanami::Slice::Router::NestedResourceContext).to be_a(Class)
      expect(Hanami::Slice::Router::NestedResourceBuilder).to be_a(Class)
      
      # Test that NestedResourceBuilder still inherits from ResourceBuilder
      expect(Hanami::Slice::Router::NestedResourceBuilder.superclass).to eq(Hanami::Slice::Router::ResourceBuilder)
    end
  end
end
