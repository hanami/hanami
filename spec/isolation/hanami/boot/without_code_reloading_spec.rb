RSpec.describe "Hanami.boot", type: :integration do
  context "without code reloading" do
    it "doesn't reloads configurations" do
      with_project("bookshelf", exclude_gems: ["shotgun"]) do
        generate "app admin"
        generate_model "user"
        generate_migration "create_users", <<-EOF
Hanami::Model.migration do
  change do
    create_table :users do
      primary_key :id
      column :name, String
    end
  end
end
EOF
        hanami "db prepare"

        write "script/components", <<-EOF
require "\#{__dir__}/../config/environment"
Hanami.boot
puts "code reloading: \#{Hanami.code_reloading?}"

mailer_configuration = Hanami::Components['mailer.configuration']
model_configuration  = Hanami::Components['model.configuration']

admin_configuration = Hanami::Components['admin.configuration']
web_configuration   = Hanami::Components['web.configuration']

Hanami.boot

puts "mailer configuration: \#{mailer_configuration.object_id == Hanami::Components['mailer.configuration'].object_id}"
puts "model configuration: \#{model_configuration.object_id == Hanami::Components['model.configuration'].object_id}"

puts "admin configuration: \#{admin_configuration.object_id == Hanami::Components['admin.configuration'].object_id}"
puts "web configuration: \#{web_configuration.object_id == Hanami::Components['web.configuration'].object_id}"
EOF

        bundle_exec "ruby script/components"

        expect(out).to include("code reloading: false")

        expect(out).to include("mailer configuration: true")
        expect(out).to include("model configuration: true")

        expect(out).to include("admin configuration: true")
        expect(out).to include("web configuration: true")
      end
    end
  end
end
