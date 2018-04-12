RSpec.describe "Hanami.boot", type: :integration do
  context "without hanami-model" do
    it "boots all the project's components" do
      project_without_hanami_model do
        generate "app admin"

        write "script/components", <<-EOF
require "\#{__dir__}/../config/environment"
Hanami.boot

puts "all: \#{Hanami::Components['all']}"
puts "apps: \#{Hanami::Components['apps']}"

puts "model: \#{Hanami::Components['model'].inspect}"
puts "model.sql: \#{Hanami::Components['model.sql'].inspect}"
puts "model.configuration: \#{Hanami::Components['model.configuration'].inspect}"
puts "model.bundled: \#{Hanami::Components['model.bundled'].inspect}"

puts "admin: \#{Hanami::Components['admin']}"
puts "web: \#{Hanami::Components['web']}"

puts "admin.configuration: \#{Hanami::Components['admin.configuration'].class}"
puts "web.configuration: \#{Hanami::Components['web.configuration'].class}"

puts "Hanami::Model: \#{defined?(Hanami::Model).inspect}"

puts "Admin::Controllers: \#{defined?(Admin::Controllers)}"
puts "Web::Controllers: \#{defined?(Web::Controllers)}"

puts "Admin::Views: \#{defined?(Admin::Views)}"
puts "Web::Views: \#{defined?(Web::Views)}"
EOF

        bundle_exec "ruby script/components"

        expect(out).to include("all: true")
        expect(out).to include("apps: true")

        expect(out).to include("model: nil")
        expect(out).to include("model.sql: nil")
        expect(out).to include("model.configuration: nil")
        expect(out).to include("model.bundled: nil")

        expect(out).to include("admin: true")
        expect(out).to include("web: true")

        expect(out).to include("admin.configuration: Hanami::ApplicationConfiguration")
        expect(out).to include("web.configuration: Hanami::ApplicationConfiguration")

        expect(out).to include("Hanami::Model: nil")

        expect(out).to include("Admin::Controllers: constant")
        expect(out).to include("Web::Controllers: constant")

        expect(out).to include("Admin::Views: constant")
        expect(out).to include("Web::Views: constant")
      end
    end
  end
end
