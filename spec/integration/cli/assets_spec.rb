RSpec.describe "hanami assets", type: :integration do
  it "prints subcommands" do
    with_project do
      output = <<-OUT
Commands:
  hanami assets precompile              # Precompile assets for deployment
OUT

      run_command "hanami assets", output, exit_status: 1
    end
  end
end
