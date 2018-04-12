RSpec.describe "Hanami.boot", type: :integration do
  context "with hanami-model" do
    it "boots all the project's components" do
      with_project do
        generate "app admin"

        require Pathname.new(Dir.pwd).join("config", "environment")
        expect(Hanami::Model).to receive(:disconnect)
        expect(Hanami.boot).to be(nil)

        expect(Hanami::Components['all']).to  be(true)
        expect(Hanami::Components['apps']).to be(true)

        expect(Hanami::Components['model']).to               be(true)
        expect(Hanami::Components['model.sql']).to           be(true)
        expect(Hanami::Components['model.configuration']).to be_kind_of(Hanami::Model::Configuration)
        expect(Hanami::Components['model.bundled']).to       be(true)

        expect(Hanami::Components['admin']).to be(true)
        expect(Hanami::Components['web']).to   be(true)

        expect(Hanami::Components['admin.configuration']).to be_kind_of(Hanami::ApplicationConfiguration)
        expect(Hanami::Components['web.configuration']).to   be_kind_of(Hanami::ApplicationConfiguration)

        expect(defined?(Hanami::Model)).to eq("constant")

        expect(defined?(Admin::Controllers)).to eq("constant")
        expect(defined?(Web::Controllers)).to   eq("constant")

        expect(defined?(Admin::Views)).to eq("constant")
        expect(defined?(Web::Views)).to   eq("constant")
      end
    end
  end
end
