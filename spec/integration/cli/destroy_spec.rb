RSpec.describe "hanami destroy", type: :integration do
  it "prints subcommands" do
    with_project do
      output = <<-OUT
Commands:
  hanami destroy action APP ACTION                     # Destroy an action from app
  hanami destroy app APP                               # Destroy an app
  hanami destroy mailer MAILER                         # Destroy a mailer
  hanami destroy migration MIGRATION                   # Destroy a migration
  hanami destroy model MODEL                           # Destroy a model
OUT

      run_command "hanami destroy", output, exit_status: 1
    end
  end
end
