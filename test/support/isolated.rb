require 'excon'
require_relative './free_tcp_port'

module Minitest
  module Isolated
    def self.included(context)
      context.class_eval do
        before do
          @assets_directory = root.join('public', 'assets')
          @assets_directory.rmtree if @assets_directory.exist?

          @tmp = root.join('tmp')
          @tmp.rmtree if @tmp.exist?
          @tmp.mkpath

          @port = FreeTCPPort.new
          # options = {}
          options = {out: '/dev/null', err: '/dev/null'}
          Process.spawn("cd #{ root } && bundle exec hanami server --port=#{ @port } --pid=tmp/server.pid", options)
          @pid = server_pid
          Process.detach(@pid)
        end

        after do
          unless @pid.nil?
            Process.kill("INT", @pid)
            Process.wait
          end

          # @assets_directory.rmtree if @assets_directory.exist?
          if @tmp.exist?
            @tmp.rmtree rescue nil
          end
        end
      end
    end

    private

    def get(path)
      http.get(path: path, read_timeout: 360)
    end

    def http
      Excon.new("http://localhost:#{ @port }")
    end

    def server_pid
      counter = 0
      pid     = @tmp.join('server.pid')

      while counter < 5 do
        if pid.exist?
          return pid.read.to_i
        end

        counter += 1
        sleep 1
      end
    end
  end
end
