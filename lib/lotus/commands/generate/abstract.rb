require 'lotus/environment'
require 'lotus/generators/generatable'
require 'lotus/generators/test_framework'
require 'lotus/version'
require 'lotus/utils/string'

module Lotus
  module Commands
    class Generate
      class Abstract

        include Lotus::Generators::Generatable

        attr_reader :options, :target_path, :test_framework

        def initialize(options)
          @options = Lotus::Utils::Hash.new(options).symbolize!
          assert_options!

          @target_path = Pathname.pwd
          @test_framework = Lotus::Generators::TestFramework.new(options[:test])
        end

        def template_source_path
          generator = self.class.name.split('::').last.downcase
          Pathname.new(::File.dirname(__FILE__) + "/../../generators/#{generator}/").realpath
        end

        private

        def lotusrc_options
          @lotusrc_options ||= Lotusrc.new(target_path).read
        end

        def environment
          @environment ||= Lotus::Environment.new(options)
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
