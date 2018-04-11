RSpec.describe "Hanami.app?", type: :integration do
  before { ENV.delete('HANAMI_APPS') }

  context 'when HANAMI_APPS is missing' do
    it "checks if the given app matches the allowed one" do
      expect(Hanami.app?(:web)).to   be(true)
      expect(Hanami.app?('web')).to  be(true)
      expect(Hanami.app?(:admin)).to be(true)
    end
  end

  context 'when HANAMI_APPS is empty' do
    it "checks if the given app matches the allowed one" do
      ENV['HANAMI_APPS'] = ''

      expect(Hanami.app?(:web)).to   be(false)
      expect(Hanami.app?('web')).to  be(false)
      expect(Hanami.app?(:admin)).to be(false)
    end
  end

  context 'when HANAMI_APPS is not empty' do
    it "checks if the given app matches the allowed one" do
      ENV['HANAMI_APPS'] = 'web,api'

      expect(Hanami.app?(:web)).to   be(true)
      expect(Hanami.app?('web')).to  be(true)
      expect(Hanami.app?(:api)).to   be(true)
      expect(Hanami.app?(:admin)).to be(false)
    end
  end
end
