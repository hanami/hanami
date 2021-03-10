# frozen_string_literal: true

require "open3"
require "etc"

module Hanami
  module Utils
    class Bundler
      class Result
        SUCCESSFUL_EXIT_CODE = 0
        private_constant :SUCCESSFUL_EXIT_CODE

        attr_reader :exit_code, :out, :err

        def initialize(exit_code:, out:, err:)
          @exit_code = exit_code
          @out = out
          @err = err
        end

        def successful?
          exit_code == SUCCESSFUL_EXIT_CODE
        end
      end

      def initialize(fs:)
        @fs = fs
      end

      def install
        parallelism_level = Etc.nprocessors
        bundle "install --jobs=#{parallelism_level} --quiet --no-color"
      end

      def install!
        install.tap do |result|
          raise "Bundle install failed\n\n\n#{result.err.inspect}" unless result.successful?
        end
      end

      def bundle_exec(cmd, env: nil, &blk)
        bundle("exec #{cmd}", env: env, &blk)
      end

      def bundle(cmd, env: nil, &blk)
        bundle_bin = which("bundle")
        hanami_env = "HANAMI_ENV=#{env} " unless env.nil?

        system_exec("#{hanami_env}#{bundle_bin} #{cmd}", &blk)
      end

      private

      attr_reader :fs

      # Adapted from Bundler source code
      #
      # Bundler is released under MIT license
      # https://github.com/bundler/bundler/blob/master/LICENSE.md
      #
      # A special "thank you" goes to Bundler maintainers and contributors.
      #
      # Also adapted from `hanami-devtools` source code
      def system_exec(cmd, env: {"BUNDLE_GEMFILE" => fs.expand_path("Gemfile")})
        exitstatus = nil
        out = nil
        err = nil

        ::Bundler.with_unbundled_env do
          Open3.popen3(env, cmd) do |stdin, stdout, stderr, wait_thr|
            yield stdin, stdout, wait_thr if block_given?
            stdin.close

            exitstatus = wait_thr&.value&.exitstatus
            out = Thread.new { stdout.read }.value.strip
            err = Thread.new { stderr.read }.value.strip
          end
        end

        Result.new(exit_code: exitstatus, out: out, err: err)
      end

      # Adapted from https://stackoverflow.com/a/5471032/498386
      def which(cmd)
        exts = ENV["PATHEXT"] ? ENV["PATHEXT"].split(";") : [""]

        ENV["PATH"].split(File::PATH_SEPARATOR).each do |path|
          exts.each do |ext|
            exe = fs.join(path, "#{cmd}#{ext}")
            return exe if fs.executable?(exe) && !fs.directory?(exe)
          end
        end

        nil
      end
    end
  end
end
