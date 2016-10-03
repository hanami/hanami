RSpec.describe "hanami routes", type: :cli do
  it "prints application routes" do
    with_project do
      generate "app admin"

      generate "action web home#index --url=/"
      generate "action web books#create --url=/books --method=POST"

      generate "action admin home#index --url=/"

      hanami "routes"

      expect(out).to eq "Name Method     Path                           Action                        \n\n                     GET, HEAD  /admin                         Admin::Controllers::Home::Index\n                     POST       /books                         Web::Controllers::Books::Create\n                     GET, HEAD  /                              Web::Controllers::Home::Index"
    end
  end
end
