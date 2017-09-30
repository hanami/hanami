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
        write "script/components", <<-EOF

          require "\#{__dir__}/../config/environment"
          Hanami::Components.resolve('mailer.configuration')

          configuration = Hanami::Components['mailer.configuration']
          puts "mailer.configuration.delivery_method: \#{configuration.delivery_method.first.inspect}"
EOF

        bundle_exec "ruby script/components"

        expect(out).to include("mailer.configuration.delivery_method: :smtp")
      end
    end
  end
end
