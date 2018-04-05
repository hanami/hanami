begin
  require "bundler/inline"
rescue LoadError => e
  $stderr.puts "Bundler version 1.10 or later is required. Please update your Bundler"
  raise e
end

gemfile(true) do
  source "https://rubygems.org"

  gem "rake"
  gem "hanami",       github: "hanami/hanami"
  gem "hanami-model", github: "hanami/model"
  gem "sqlite3"
  gem "minitest"
end

require "hanami"
require "hanami/model"
require "hanami/model/sql"
require "minitest/autorun"

Hanami.configure do
  model do
    adapter :sql, "sqlite::memory"
  end
end

class Book < Hanami::Entity
end

class BookRepository < Hanami::Repository
end

class Author < Hanami::Entity
end

class AuthorRepository < Hanami::Repository
  associations do
    has_many :books
  end

  def add_book(author, data)
    assoc(:books, author).add(data)
  end
end

Hanami.boot

Hanami::Model.migration do
  change do
    create_table :authors do
      primary_key :id

      column :name, String
    end

    create_table :books do
      primary_key :id

      foreign_key :author_id, :authors, null: false

      column :title, String
    end
  end
end.run

class BugTest < Minitest::Test
  def test_association_stuff
    author_repository = AuthorRepository.new
    book_repository = BookRepository.new
    author = author_repository.create(name: "Leo Tolstoy")

    # author_repository.add_book(author, title: "Childhood")
    # author_repository.add_book(author, title: "Boyhood")
    # author_repository.add_book(author, title: "Youth")

    assert_equal author_repository.all.count, 1
    # assert_equal book_repository.all.count, 3
  end
end
