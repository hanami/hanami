RSpec.describe 'hanami version', type: :cli do
  it 'prints current version' do
    with_project do
      run_command 'hanami version', "v#{Hanami::VERSION}"
    end
  end

  # FIXME: once hanami-cli will support aliases again
  xit 'prints current version with -v alias' do
    with_project do
      run_command 'hanami -v', "v#{Hanami::VERSION}"
    end
  end

  xit 'prints current version with --version alias' do
    with_project do
      run_command 'hanami --version', "v#{Hanami::VERSION}"
    end
  end
end
