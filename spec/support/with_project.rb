require_relative 'silently'
require_relative 'bundler'
require_relative 'with_tmp_directory'
require_relative 'within_project_directory'

module RSpec
  module Support
    module WithProject
      private

      KNOWN_ARGUMENTS = [:database, :template, :test].freeze

      def with_project(project = "bookshelf", args = {})
        with_tmp_directory do
          create_project(project, args)

          within_project_directory(project) do
            setup_gemfile(gems: gem_dependencies(args))
            bundle_install
            yield
          end
        end
      end

      def create_project(project, args)
        silently "hanami new #{project}#{_create_project_args(args)}"
      end

      def gem_dependencies(args) # rubocop:disable Metrics/MethodLength
        result = []

        case args.fetch(:console, nil)
        when :pry
          result << 'pry'
        when :ripl
          result << 'ripl'
        end

        case args.fetch(:server, nil)
        when :puma
          result << 'puma'
        when :unicorn
          result << 'unicorn'
        when :thin
          result << 'thin'
        end

        result
      end

      def _create_project_args(args)
        return if args.empty?
        flags = args.dup.keep_if { |k, _| KNOWN_ARGUMENTS.include?(k) }

        result = flags.map do |arg, value|
          "--#{arg}=#{value}"
        end.join(" ")

        " #{result}"
      end
    end
  end
end

RSpec.configure do |config|
  config.include RSpec::Support::WithProject, type: :cli
end
