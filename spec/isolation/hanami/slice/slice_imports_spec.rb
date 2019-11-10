# frozen_string_literal: true

require "hanami/application"

module Bookshelf
  class Application < Hanami::Application
    config.slice :admin do
      import :search
    end
  end
end

module Search; end
search_slice = Hanami.application.register_slice :search, namespace: Search

module Admin; end
admin_slice = Hanami.application.register_slice :admin, namespace: Admin

module Admin
  class CreateBook
    include Deps["search.index_entity"]
  end
end

module Search
  class IndexEntity
  end
end

Admin::Slice.register "create_book" do
  Admin::CreateBook.new
end

Search::Slice.register "index_entity" do
  Search::IndexEntity.new
end

Hanami.application.routes do
  # FIXME: I really shouldn't have to do this
end

RSpec.describe "Slice imports" do
  specify "Importing a slice from another using config" do
    Hanami.boot

    expect(Admin::Slice["create_book"]).to be_an Admin::CreateBook
    expect(Admin::Slice["create_book"].index_entity).to be_a Search::IndexEntity
  end
end
