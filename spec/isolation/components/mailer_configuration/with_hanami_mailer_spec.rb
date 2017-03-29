RSpec.describe "Components: mailer.configuration", type: :cli do
  context "with hanami-mailer" do
    it "resolves mailer configuration" do
      with_project do
        require Pathname.new(Dir.pwd).join("config", "environment")
        Hanami::Components.resolve('mailer.configuration')

        expect(Hanami::Components['mailer.configuration']).to be_kind_of(Hanami::Mailer::Configuration)
      end
    end

    it "resolves mailer configuration for current environment" do
      with_project do
        unshift "config/environment.rb", "ENV['HANAMI_ENV'] = 'production'"
        require Pathname.new(Dir.pwd).join("config", "environment")
        Hanami::Components.resolve('mailer.configuration')

        configuration = Hanami::Components['mailer.configuration']
        expect(configuration.delivery_method.first).to eq(:smtp)
      end
    end
  end
end
