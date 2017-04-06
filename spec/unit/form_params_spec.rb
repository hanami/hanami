RSpec.describe Hanami::FormParams do
  let(:filtered_parameters) { [/.*password.*/, :credit_card] }
  let(:raw_params) do
    Hash[
      'post' => Hash[
        'title' => 'My Post',
        'body' => 'Blog post body',
        'credit_card' => {
          'number' => '123123123123123',
          'name' => 'Gabriel Gizotti'
        },
        'user' => {
          'name' => 'User',
          'password' => 'password1234'
        },
        'password' => 'password',
        'password_confirmation' => 'password'
      ]
    ]
  end
  let(:symbolized_params) do
    {
      post: {
        title: 'My Post',
        body: 'Blog post body',
        credit_card: '[FILTERED]',
        user: {
          name: 'User',
          password: '[FILTERED]'
        },
        password: '[FILTERED]',
        password_confirmation: '[FILTERED]'
      }
    }
  end
  let(:present_params) { described_class.new(raw_params, filtered_parameters: filtered_parameters) }
  let(:absent_params) { described_class.new(nil, filtered_parameters: filtered_parameters) }

  describe '#prepared_params' do
    it 'return pretty printed params hash if initiated with params hash' do
      expect(present_params.prepared_params).to eq(symbolized_params)
    end

    it 'return nil if initiated with nil params' do
      expect(absent_params.prepared_params).to be_nil
    end
  end

  describe '#present?' do
    it 'return true if initiated with params hash' do
      expect(present_params.present?).to eq(true)
    end

    it 'return false if initiated with nil params' do
      expect(absent_params.present?).to eq(false)
    end
  end
end
