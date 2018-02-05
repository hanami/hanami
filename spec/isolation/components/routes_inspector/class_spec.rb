require 'hanami/components/routes_inspector'

RSpec.describe Hanami::Components::RoutesInspector, type: :integration do
  describe "#inspect" do
    it "returns printable routes" do
      with_project do
        generate "app admin"
        generate "action web home#index"
        generate "action admin home#index"

        require Pathname.new(Dir.pwd).join("config", "environment")
        Hanami::Components.resolve('apps.configurations')

        inspector = described_class.new(Hanami.configuration)
        expect(inspector.inspect).to eq("                Name Method     Path                           Action                        \n\n                     GET, HEAD  /admin/home                    Admin::Controllers::Home::Index\n\n                Name Method     Path                           Action                        \n\n                     GET, HEAD  /home                          Web::Controllers::Home::Index \n")
      end
    end
  end
end
