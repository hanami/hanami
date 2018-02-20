begin
  require "bundler/inline"
rescue LoadError => e
  $stderr.puts "Bundler version 1.10 or later is required. Please update your Bundler"
  raise e
end

gemfile(true) do
  source "https://rubygems.org"

  gem "rake"
  gem "hanami-model", github: "hanami/model"
  gem "sqlite3"
  gem "rspec"
  gem "rspec-core"
end

require 'hanami/model'
require 'hanami/model/sql'

Hanami::Model.configure do
  adapter :sql, "sqlite:///#{Dir.pwd}/hanami_model_template.db"
end

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

Hanami::Model.load!

require 'rspec'
require 'rspec/autorun'

RSpec.describe 'Model' do
  let(:author_repository) { AuthorRepository.new }
  let(:book_repository) { BookRepository.new }

  subject { author_repository.create(name: "Leo Tolstoy") }

  it { expect { subject }.to change { author_repository.all.count }.by(1) }
end
