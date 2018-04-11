RSpec.describe 'hanami version', type: :integration do
  context "within a project" do
    it 'prints current version' do
      with_project do
        run_command 'hanami version', "v#{Hanami::VERSION}"
      end
    end

    it 'prints current version with v alias' do
      with_project do
        run_command 'hanami v', "v#{Hanami::VERSION}"
      end
    end

    it 'prints current version with -v alias' do
      with_project do
        run_command 'hanami -v', "v#{Hanami::VERSION}"
      end
    end

    it 'prints current version with --version alias' do
      with_project do
        run_command 'hanami --version', "v#{Hanami::VERSION}"
      end
    end

    it 'prints help message' do
      with_project do
        output = <<-OUT
Command:
  hanami version

Usage:
  hanami version

Description:
  Print Hanami version

Options:
  --help, -h                      	# Print this help
OUT

        run_command 'hanami version --help', output
      end
    end
  end

  context "outside of a project" do
    it 'prints current version' do
      run_command 'hanami version', "v#{Hanami::VERSION}"
    end

    it 'prints current version with v alias' do
      run_command 'hanami v', "v#{Hanami::VERSION}"
    end

    it 'prints current version with -v alias' do
      run_command 'hanami -v', "v#{Hanami::VERSION}"
    end

    it 'prints current version with --version alias' do
      run_command 'hanami --version', "v#{Hanami::VERSION}"
    end

    it 'prints help message' do
      output = <<-OUT
Command:
  hanami version

Usage:
  hanami version

Description:
  Print Hanami version

Options:
  --help, -h                      	# Print this help
OUT

      run_command 'hanami version --help', output
    end
  end
end
