require 'lotus/environment'
require 'lotus/generators/test_framework'
require 'lotus/version'
require 'thor'

module Lotus
  module Commands
    class Generate
      class Abstract

        attr_reader :options, :base_path, :test_framework

        def initialize(options)
          @options = Lotus::Utils::Hash.new(options).symbolize!
          assert_options!
          @base_path = Pathname.pwd
          @test_framework = Lotus::Generators::TestFramework.new(options[:test])
        end

        def start
          raise NotImplementedError
        end

        private

        def lotusrc_options
          @lotusrc_options ||= Lotusrc.new(Pathname.new(base_path)).read
        end

        def environment
          @environment ||= Lotus::Environment.new(options)
        end

        def template_source_path
          generator = self.class.name.split('::').last.downcase
          Pathname.new(::File.dirname(__FILE__) + "/../../generators/#{generator}/").realpath
        end

        def template_engine
          options.fetch(:template, default_template_engine)
        end

        def default_template_engine
          lotusrc_options.fetch(:template)
        end

        def assert_options!
          if options.nil?
            raise ArgumentError.new('options must not be nil')
          end
        end

      end
    end
  end
end
