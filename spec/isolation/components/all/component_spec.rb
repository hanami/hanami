RSpec.describe "Components: all", type: :integration do
  it "loads all" do
    with_project do
      generate "app admin"
      generate "action web home#index"

      require Pathname.new(Dir.pwd).join("config", "environment")
      Hanami::Components.resolve('all')

      expect(Hanami::Components['all']).to be(true)

      expect(Hanami::Components['model.configuration']).to_not be(nil)
      expect(Hanami::Components['model']).to_not               be(nil)

      expect(Hanami::Components['mailer.configuration']).to_not be(nil)
      expect(Hanami::Components['mailer']).to_not               be(nil)


      expect(Hanami::Components['web']).to_not   be(nil)
      expect(Hanami::Components['admin']).to_not be(nil)

      expect(Hanami::Components['finalizers']).to_not be(nil)
    end
  end
end
