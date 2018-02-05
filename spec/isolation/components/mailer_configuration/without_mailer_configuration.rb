RSpec.describe "Components: mailer.configuration", type: :integration do
  context "without mailer configuration" do
    it "doesn't resolve mailer configuration" do
      with_project do
        environment_file = Pathname.new(Dir.pwd).join("config", "environment")
        remove_block "config/environment.rb", "mailer do"

        require environment_file
        Hanami::Components.resolve('mailer.configuration')

        expect(Hanami::Components['mailer.configuration']).to be(nil)
      end
    end
  end
end
