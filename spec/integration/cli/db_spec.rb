RSpec.describe "hanami db", type: :integration do
  it "prints subcommands" do
    with_project do
      output = <<-OUT
Commands:
  hanami db apply                           # Migrate, dump the SQL schema, and delete the migrations (experimental)
  hanami db console                         # Starts a database console
  hanami db create                          # Create the database (only for development/test)
  hanami db drop                            # Drop the database (only for development/test)
  hanami db migrate [VERSION]               # Migrate the database
  hanami db prepare                         # Drop, create, and migrate the database (only for development/test)
  hanami db rollback [STEPS]                # Rollback migrations
  hanami db version                         # Print the current migrated version
OUT

      run_command "hanami db", output, exit_status: 1
    end
  end
end
