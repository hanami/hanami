# frozen_string_literal: true

module Hanami
  # Hanami CLI
  #
  # @since 1.1.0
  class CLI
    module Commands
      # @since 1.1.0
      # @api private
      class New < Command
        desc "Generate a new Hanami project"
        argument :project, required: true, desc: "The project name"

        example [
          "bookshelf                     # Basic usage",
          "bookshelf --test=rspec        # Setup RSpec testing framework",
          "bookshelf --database=postgres # Setup Postgres database",
          "bookshelf --template=slim     # Setup Slim template engine",
          "bookshelf --hanami-head       # Use Hanami HEAD"
        ]

        def initialize
          @templates = Templates.new(self.class.superclass)
        end

        attr_reader :templates

        # @since 1.1.0
        # @api private
        def call(project:, **options)
          pwd = ::File.basename(Dir.pwd) if project == "."
          project = Utils::String.underscore(pwd || project)

          require 'debug'

          context = Context.new(
            project: project,
            project_module: Utils::String.classify(project),
            options: options
          )

          directory = project_directory(project_name, project)
          files.mkdir(directory)

          Dir.chdir(directory) do
            init_git
            generate_application_templates(context)
          end
        end

        private

        # @since 1.1.0
        # @api private
        def project_directory(project_name, project)
          return Dir.pwd if project_name == '.'
          project
        end

        # @since 1.1.0
        # @api private
        #
        # rubocop:disable Metrics/AbcSize
        # rubocop:disable Metrics/MethodLength
        def generate_application_templates(context)
          source      = templates.find("lib", "project.erb")
          destination = project.project(context)
          generate_file(source, destination, context)
        end
        # rubocop:enable Metrics/MethodLength
        # rubocop:enable Metrics/AbcSize

        # @since 1.1.0
        # @api private
        def init_git
          return if git_dir_present?

          say(:run, "git init . from \".\"")
          system("git init #{Shellwords.escape(target)}", out: File::NULL)
        end

        # @since 1.1.0
        # @api private
        def git_dir_present?
          files.directory?('.git')
        end
      end
    end

    register "new", Commands::New
  end
end
