RSpec.describe "Hanami.boot", type: :integration do
  context "with code reloading" do
    it "reloads configurations" do
      with_project do
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

        require Pathname.new(Dir.pwd).join("config", "environment")

        Hanami.boot
        expect(Hanami.code_reloading?).to be(true)

        mailer_configuration = Hanami::Components['mailer.configuration']
        model_configuration  = Hanami::Components['model.configuration']

        admin_configuration = Hanami::Components['admin.configuration']
        web_configuration   = Hanami::Components['web.configuration']

        Hanami.boot

        expect(Hanami::Components['mailer.configuration'].object_id).to_not eq(mailer_configuration.object_id)
        expect(Hanami::Components['model.configuration'].object_id).to_not eq(model_configuration.object_id)

        expect(Hanami::Components['admin.configuration'].object_id).to_not eq(admin_configuration.object_id)
        expect(Hanami::Components['web.configuration'].object_id).to_not eq(web_configuration.object_id)
      end
    end
  end
end
