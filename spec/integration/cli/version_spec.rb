RSpec.describe 'hanami version', type: :cli do
  it 'prints current version' do
    with_project do
      run_command 'hanami version', "v#{Hanami::VERSION}"
    end
  end
end
