RSpec.describe "Rake: assets:precompile", type: :integration do
  it "precompiles assets" do
    with_project do
      bundle_exec "rake assets:precompile"

      expect("public/assets.json").to be_an_existing_file
    end
  end

  it "exit the parent process with the child exit status" do
    with_project do
      FileUtils.rm_rf("apps")

      bundle_exec "rake assets:precompile"
      expect(exitstatus).to be(1)
    end
  end
end
