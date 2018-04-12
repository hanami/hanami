RSpec.describe "Rake: environment", type: :integration do
  it "loads the project" do
    with_project do
      generate_migrations
      generate_model "author"
      hanami "db prepare"

      append "Rakefile", <<-EOF
task database_counts: :environment do
puts "users: \#{AuthorRepository.new.all.count}"
end
EOF

      bundle_exec "rake database_counts"

      expect(out).to match("users: 0")
    end
  end
end
