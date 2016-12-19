RSpec.describe Hanami::VERSION do
  it 'returns current version' do
    expect(subject).to eq('0.9.2')
  end
end
