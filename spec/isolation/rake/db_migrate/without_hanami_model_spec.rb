RSpec.describe "Rake: db:migrate", type: :integration do
  context "without hanami-model" do
    it "removes Rake task" do
      project_without_hanami_model do
        bundle_exec "rake db:migrate"
        expect(err).to include("Don't know how to build task 'db:migrate'")
      end
    end
  end
end
