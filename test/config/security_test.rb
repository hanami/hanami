require 'test_helper'

describe Hanami::Config::Security do
  let(:security) { Hanami::Config::Security.new }

  describe '#content_security_policy' do
    describe 'when the argument is nil' do
      before do
        security.content_security_policy('img-src localhost')
      end

      it 'returns the value' do
        security.content_security_policy.must_equal('img-src localhost')
        security.content_security_policy(nil).must_equal('img-src localhost')
      end
    end

    describe 'when the argument is not single line string' do
      it 'assigns new value' do
        security.content_security_policy('script-src example')
        security.content_security_policy.must_equal('script-src example')
      end
    end

    describe 'when the argument is multiline string' do
      it 'concatenates all lines into one and assigns new value' do
        security.content_security_policy(%{
          script-src example;
          img-src localhost
        })
        security.content_security_policy.must_equal('script-src example; img-src localhost')
      end
    end
  end

  describe '#x_frame_options' do
    describe 'when the argument is nil' do
      before do
        security.x_frame_options('ALLOW ALL')
      end

      it 'returns the value' do
        security.x_frame_options.must_equal('ALLOW ALL')
        security.x_frame_options(nil).must_equal('ALLOW ALL')
      end
    end

    describe 'when the argument is not nil' do
      it 'assigns new value' do
        security.x_frame_options('DENY')
        security.x_frame_options.must_equal('DENY')
      end
    end
  end
end
