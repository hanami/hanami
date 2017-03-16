RSpec.describe Hanami::VERSION do
  it 'returns current version' do
    expect(subject).to eq('1.0.0.beta3')
  end
end
