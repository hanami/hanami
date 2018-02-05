RSpec.describe "Components: mailer", type: :integration do
  context "with hanami-mailer" do
    it "resolves mailer" do
      with_project do
        require Pathname.new(Dir.pwd).join("config", "environment")
        Hanami::Components.resolve('mailer')

        expect(Hanami::Components['mailer']).to               be(true)
        expect(Hanami::Components['mailer.configuration']).to be_truthy
      end
    end
  end
end
