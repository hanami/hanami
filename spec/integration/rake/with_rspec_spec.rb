RSpec.describe "Rake: default task", type: :integration do
  context "with RSpec" do
    it "runs tests" do
      with_project("bookshelf", test: "rspec") do
        setup_model

        prepare_development_database
        generate_development_data

        prepare_test_database

        generate 'mailer bookshelf'

        write "spec/bookshelf/repositories/book_repository_spec.rb", <<-EOF
RSpec.describe BookRepository do
  before do
    described_class.new.clear
  end

  it 'finds all the records' do
    expect(described_class.new.all.to_a).to eq([])
  end
end
EOF

        bundle_exec "rake"

        # The default mailer_spec fails on purpose so you set the correct delivery information.
        expect(out).to include("3 examples, 1 failure")

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
