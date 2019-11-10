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
Hanami.application.register_slice :search, namespace: Search

module Admin; end
Hanami.application.register_slice :admin, namespace: Admin

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

RSpec.describe "Slice imports" do
  specify "Slices import application; importing a slice from another using config" do
    Hanami.init

    expect(Admin::Slice["search.index_entity"]).to be
    expect(Admin::Slice.container).not_to be_finalized
    expect(Search::Slice.container).not_to be_finalized
  end
end
