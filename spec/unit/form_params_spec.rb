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
  let(:pretty_generated_params) do
    "{\n" \
    "  \"post\": {\n" \
    "    \"title\": \"My Post\",\n" \
    "    \"body\": \"Blog post body\",\n" \
    "    \"credit_card\": \"[FILTERED]\",\n" \
    "    \"user\": {\n" \
    "      \"name\": \"User\",\n" \
    "      \"password\": \"[FILTERED]\"\n" \
    "    },\n" \
    "    \"password\": \"[FILTERED]\",\n" \
    "    \"password_confirmation\": \"[FILTERED]\"\n" \
    "  }\n" \
    "}"
  end
  let(:present_params) { described_class.new(raw_params, filtered_parameters: filtered_parameters) }
  let(:absent_params) { described_class.new(nil, filtered_parameters: filtered_parameters) }

  describe '#prepared_params' do
    it 'return pretty printed params hash if initiated with params hash' do
      expect(present_params.prepared_params).to eq(pretty_generated_params)
    end

    it 'return nil if initiated with nil params' do
      expect(absent_params.prepared_params).to be_nil
    end
  end

  describe '#log_message' do
    it 'return true if initiated with params hash' do
      expect(present_params.log_message).to eq("Parameters: #{pretty_generated_params}")
    end

    it 'return nil if initiated with nil params' do
      expect(absent_params.log_message).to be_nil
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
