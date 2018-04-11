RSpec.describe "hanami generate", type: :integration do
  it "prints subcommands" do
    with_project do
      output = <<-OUT
Commands:
  hanami generate action APP ACTION                     # Generate an action for app
  hanami generate app APP                               # Generate an app
  hanami generate mailer MAILER                         # Generate a mailer
  hanami generate migration MIGRATION                   # Generate a migration
  hanami generate model MODEL                           # Generate a model
  hanami generate secret [APP]                          # Generate session secret
OUT

      run_command "hanami generate", output, exit_status: 1
    end
  end
end
