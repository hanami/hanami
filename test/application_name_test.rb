require 'test_helper'
require 'lotus/application_name'

describe Lotus::ApplicationName do

  describe "formats" do

    describe "#to_s" do
      it "renders downcased" do
        application_name = Lotus::ApplicationName.new("MY-APP")
        application_name.to_s.must_equal "my_app"
      end

      it "renders trimmed" do
        application_name = Lotus::ApplicationName.new(" my-app ")
        application_name.to_s.must_equal "my_app"
      end

      it "renders internal spaces as underscores" do
        application_name = Lotus::ApplicationName.new("my app")
        application_name.to_s.must_equal "my_app"
      end

      it "renders with underscores de-duplicated" do
        application_name = Lotus::ApplicationName.new("my _app")
        application_name.to_s.must_equal "my_app"
      end
    end


    describe "to_env_s" do
      it "renders uppercased with non-alphanumeric characters as underscores" do
        application_name = Lotus::ApplicationName.new("my-app")
        application_name.to_env_s.must_equal "MY_APP"
      end
    end
  end


  describe "reserved words" do
    it "prohibits 'lotus'" do
      -> { Lotus::ApplicationName.new("lotus") }.must_raise RuntimeError
    end
  end
end
