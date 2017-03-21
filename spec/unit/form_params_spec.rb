RSpec.describe Hanami::FormParams do
  let(:raw_params) do
    Hash[
      'post' => Hash[
        'title' => 'My Post',
        'body' => 'Blog post body'
      ]
    ]
  end
  let(:pretty_generated_params) { "{\n" + "  \"post\": {\n" + "    \"title\": \"My Post\",\n" + "    \"body\": \"Blog post body\"\n" + "  }\n" + "}" }
  let(:present_params) { described_class.new(raw_params) }
  let(:absent_params) { described_class.new(nil) }

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
