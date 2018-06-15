RSpec.describe "Hanami.configure" do
  before do
    application   = app
    model_config  = model_configuration
    mailer_config = mailer_configuration

    Hanami.configure do
      mount application, at: '/'
      model(&model_config)
      mailer(&mailer_config)
    end
  end

  let(:app) { double('app') }

  let(:model_configuration) do
    lambda do
      adapter :sql, uri: 'file://path/to/db.sqlite'

      migrations 'db/migrations'
      schema     'db/schema.sql'
    end
  end

  let(:mailer_configuration) do
    lambda do
      delivery :test
    end
  end

  it "setups apps" do
    mounted = Hanami.configuration.mounted
    expect(mounted[app]).to eq(Hanami::Configuration::App.new(app, '/'))
  end

  it "holds model configuration" do
    config = Hanami.configuration.model
    expect(config).to eq(model_configuration)
  end

  it "holds mailer configuration" do
    config = Hanami.configuration.mailer_settings
    expect(config).to eq([mailer_configuration])
  end

  describe 'inflector' do
    it "holds inflector" do
      expect(Hanami.configuration.inflector).to be_a_kind_of(Dry::Inflector)
      expect(Hanami.configuration.inflector.pluralize("virus")).to eq("viri")
    end

    it "configures inflector rules" do
      Hanami.configure do
        inflector do |rule|
          rule.plural "virus", "viruses"
        end
      end

      expect(Hanami.configuration.inflector.pluralize("virus")).to eq("viruses")
    end
  end
end
