# frozen_string_literal: true

require "hanami/web/rack_logger"
require "dry/logger"
require "stringio"
require "rack/mock"

RSpec.describe Hanami::Web::RackLogger do
  subject { described_class.new(logger) }

  let(:logger) do
    Dry.Logger(
      app_name,
      stream:,
      level: :debug,
      # Use Hanami's default filters
      filters: Hanami::Config::Logger.new(env: :development, app_name: nil).filters,
      formatter: :rack,
      template: "[%<progname>s] [%<severity>s] [%<time>s] %<message>s"
    )
  end

  let(:stream) { StringIO.new }
  let(:app_name) { "my_app" }

  describe "#initialize" do
    it "returns an instance of #{described_class}" do
      expect(subject).to be_kind_of(described_class)
    end
  end

  describe "#log_request" do
    it "logs current request" do
      time = Time.parse("2022-02-04 11:38:25.218816 +0100")
      expect(Time).to receive(:now).at_least(:once).and_return(time)

      path = "/users"
      ip = "127.0.0.1"
      status = 200
      elapsed = 0.0001
      content_length = 23
      verb = "POST"

      env = Rack::MockRequest.env_for(path, method: verb)
      env["CONTENT_LENGTH"] = content_length
      env["REMOTE_ADDR"] = ip

      params = {"user" => {"password" => "secret"}}
      env["router.params"] = params

      subject.log_request(env, status, elapsed)

      stream.rewind
      actual = stream.read

      if RUBY_VERSION < "3.4"
        expect(actual).to eql(<<~LOG)
          [#{app_name}] [INFO] [#{time}] #{verb} #{status} #{elapsed}µs #{ip} #{path} #{content_length}
            {"user"=>{"password"=>"[FILTERED]"}}
        LOG
      else
        expect(actual).to eql(<<~LOG)
          [#{app_name}] [INFO] [#{time}] #{verb} #{status} #{elapsed}µs #{ip} #{path} #{content_length}
            {"user" => {"password" => "[FILTERED]"}}
        LOG
      end
    end

    it "filters sensitive params" do
      env = Rack::MockRequest.env_for("/users", method: "POST")
      env["router.params"] = {
        "_csrf_token" => "sensitive-1",
        "user" => {
          "name" => "Jane",
          "password" => "sensitive-2",
          "password_confirmation" => "sensitive-2",
          "api_key" => "sensitive-3",
          "encrypted_password" => "sensitive-4",
          "devices" => [{"name" => "Phone", "access_token" => "sensitive-5"}]
        },
        "client_secret" => "sensitive-6"
      }

      subject.log_request(env, 200, 0.1)

      stream.rewind
      actual = stream.read

      expect(actual).to include("Jane", "Phone")
      expect(actual).not_to include("sensitive")
    end

    context "ip" do
      it "takes into account HTTP proxy forwarding" do
        env = Rack::MockRequest.env_for("/")
        env["REMOTE_ADDR"] = remote = "127.0.0.1"
        env["HTTP_X_FORWARDED_FOR"] = forwarded = "::1"

        subject.log_request(env, 200, 0.1)

        stream.rewind
        actual = stream.read

        expect(actual).to include(forwarded)
        expect(actual).to_not include(remote)
      end
    end

    context "path prefix" do
      it "logs full referenced relative path" do
        env = Rack::MockRequest.env_for(path = "/users")
        env["SCRIPT_NAME"] = script_name = "/v1"

        subject.log_request(env, 200, 0.1)

        stream.rewind
        actual = stream.read

        expect(actual).to include(script_name + path)
      end
    end
  end
end
