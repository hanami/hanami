RSpec.describe "Rake: environment", type: :cli do
  it "loads the project" do
    with_project do
      generate_migrations
      generate_model "user"
      hanami "db prepare"

      append "Rakefile", <<-EOF
      task database_counts: :environment do
      puts "users: \#{UserRepository.new.all.count}"
      end
EOF

      bundle_exec "rake database_counts"

      expect(out).to match("users: 0")
    end
  end
end
