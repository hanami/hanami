RSpec.describe "Rake: default task", type: :integration do
  context "with Minitest" do
    it "runs tests" do
      with_project("bookshelf", test: "minitest") do
        setup_model

        prepare_development_database
        generate_development_data

        prepare_test_database

        write "spec/bookshelf/repositories/book_repository_spec.rb", <<-EOF
require 'spec_helper'

describe BookRepository do
  before do
    BookRepository.new.clear
  end

  it 'finds all the records' do
    BookRepository.new.all.to_a.must_equal []
  end
end
EOF

        bundle_exec "rake"
        expect(out).to include("2 runs, 3 assertions, 0 failures, 0 errors, 0 skips")

        assert_development_data
      end
    end
  end

  private

  def prepare_development_database
    prepare_database
  end

  def prepare_test_database
    prepare_database env: "test"
  end

  def generate_development_data
    migrate

    console do |input, _, _|
      input.puts("BookRepository.new.create(title: 'Learn Hanami')")
      input.puts("exit")
    end
  end

  def assert_development_data
    console do |input, _, _|
      input.puts("BookRepository.new.all.to_a.count")
      input.puts("exit")
    end

    expect(out).to include("\n1")
  end

  def prepare_database(env: nil)
    hanami "db prepare", env: env
  end
end
