require 'open3'
require_relative 'env'
require_relative 'silently'
require_relative 'files'

module RSpec
  module Support
    module Bundler
      def self.root
        Pathname.new(__dir__).join("..", "..")
      end

      def self.cache
        root.join("vendor", "cache")
      end

      private

      attr_reader :out, :err, :exitstatus

      def setup_gemfile(gems: [], path: "Gemfile")
        source     = "source 'file://#{cache}'"
        content    = ::File.readlines(path)
        content[0] = "#{source}\n"

        unless gems.empty? # rubocop:disable Style/IfUnlessModifier
          content.concat gems.map { |g| "gem '#{g}'\n" }
        end

        rewrite(path, content)
      end

      def bundle_install
        bundle "install --local --retry 0 --no-color"
      end

      def bundle_exec(cmd, &blk)
        bundle "exec #{cmd}", &blk
      end

      def bundle(cmd, &blk)
        ruby_bin   = which("ruby")
        bundle_bin = which("bundle")

        system_exec("#{ruby_bin} -I#{load_paths} #{bundle_bin} #{cmd}", &blk)
      end

      # Adapted from Bundler source code
      #
      # Bundler is released under MIT license
      # https://github.com/bundler/bundler/blob/master/LICENSE.md
      #
      # A special "thank you" goes to Bundler maintainers and contributors.
      #
      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/MethodLength
      def system_exec(cmd)
        Open3.popen3(RSpec::Support::Env.env, cmd) do |stdin, stdout, stderr, wait_thr|
          yield stdin, stdout, wait_thr if block_given?
          stdin.close

          @exitstatus = wait_thr && wait_thr.value.exitstatus
          @out = Thread.new { stdout.read }.value.strip
          @err = Thread.new { stderr.read }.value.strip
        end

        (@all_output ||= "") << [
          "$ #{cmd.to_s.strip}",
          out,
          err,
          @exitstatus ? "# $? => #{@exitstatus}" : "",
          "\n"
        ].reject(&:empty?).join("\n")

        @out
      end
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/AbcSize

      def load_paths
        [root.join('lib'), root.join('spec')].join(':')
      end

      def root
        RSpec::Support::Bundler.root
      end

      def cache
        RSpec::Support::Bundler.cache
      end
    end
  end
end

RSpec.configure do |config|
  config.include RSpec::Support::Bundler, type: :cli

  config.before(:all, type: :cli) do
    root  = RSpec::Support::Bundler.root
    cache = RSpec::Support::Bundler.cache
    pkg   = root.join("pkg", "hanami-#{Hanami::VERSION}.gem")

    RSpec::Support.silently "bundle package --all"
    RSpec::Support.silently "bundle exec rake build"
    RSpec::Support.silently "gem install #{pkg}"

    FileUtils.mv(pkg, cache)

    Dir.chdir(cache) do
      RSpec::Support.silently "gem generate_index"
    end
  end

  config.after(:all, type: :cli) do
    cache = RSpec::Support::Bundler.cache

    FileUtils.rm_rf(cache)

    RSpec::Support.silently "gem uninstall hanami --version '#{Hanami::VERSION}' -ax --force"
    RSpec::Support.silently "bundle install"
  end
end
