# frozen_string_literal: true

require "hanami/web/rack_logger"
require "hanami/logger"
require "stringio"
require "rack/mock"

RSpec.describe Hanami::Web::RackLogger do
  subject { described_class.new(logger) }
  let(:logger) { Hanami::Logger.new(application_name, stream: stream, level: Hanami::Logger::DEBUG, filter: filters) }
  let(:stream) { StringIO.new }
  let(:filters) { ["user.password"] }
  let(:application_name) { "my_app" }

  describe "#initialize" do
    it "returns an instance of #{described_class}" do
      expect(subject).to be_kind_of(described_class)
    end
  end

  describe "#log_request" do
    it "logs current request" do
      path = "/users"
      ip = "127.0.0.1"
      status = 200
      time = 0.0001
      content_length = 23
      verb = "POST"

      env = Rack::MockRequest.env_for(path, method: verb)
      env["Content-Length"] = content_length
      env["REMOTE_ADDR"] = ip

      params = {"user" => {"password" => "secret"}}
      env["router.params"] = params

      subject.log_request(env, status, time)

      stream.rewind
      actual = stream.read

      expect(actual).to include(%([#{application_name}] [INFO] [#{time}] #{verb} #{status} #{ip} #{path} #{content_length} {"user"=>{"password"=>"[FILTERED]"}}))
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
