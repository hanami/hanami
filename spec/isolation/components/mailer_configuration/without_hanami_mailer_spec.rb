RSpec.describe "Components: mailer.configuration", type: :cli do
  context "without hanami-mailer" do
    it "resolves mailer configuration" do
      with_project do
        environment_file = Pathname.new(Dir.pwd).join("config", "environment")
        replace "#{environment_file}.rb", "delivery :test", ""

        require environment_file
        Hanami::Components.resolve('mailer.configuration')

        expect(Hanami::Components['mailer.configuration']).to be nil
      end
    end
  end
end
