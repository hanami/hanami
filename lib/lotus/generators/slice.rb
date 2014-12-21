require 'securerandom'
require 'lotus/generators/abstract'
require 'lotus/utils/string'

module Lotus
  module Generators
    class Slice < Abstract
      def initialize(command)
        super

        @slice_name            = options.fetch(:application)
        @upcase_slice_name     = @slice_name.upcase
        @classified_slice_name = Utils::String.new(@slice_name).classify

        @source                = Pathname.new(::File.dirname(__FILE__) + '/../generators/slice')
        @target                = target.join('apps', @slice_name)

        @slice_base_url        = options.fetch(:application_base_url)

        cli.class.source_root(@source)
      end

      def start
        opts = {
          slice_name:            @slice_name,
          upcase_slice_name:     @upcase_slice_name,
          classified_slice_name: @classified_slice_name,
          slice_base_url:        @slice_base_url
        }

        templates = {
          'application.rb.tt'                 => 'application.rb',
          'config/routes.rb.tt'               => 'config/routes.rb',
          'config/mapping.rb.tt'              => 'config/mapping.rb',
          'views/application_layout.rb.tt'    => 'views/application_layout.rb',
          'templates/application.html.erb.tt' => 'templates/application.html.erb',
        }

        empty_directories = [
          "controllers",
          "public/javascripts",
          "public/stylesheets"
        ]

        case options[:test]
        when 'rspec'
        else # minitest (default)
          empty_directories << [
            "../../spec/#{ opts[:slice_name] }/features",
            "../../spec/#{ opts[:slice_name] }/controllers",
            "../../spec/#{ opts[:slice_name] }/views"
          ]
        end

        ##
        # config/environment.rb
        #

        # Add "require_relative '../apps/web/application'"
        cli.gsub_file target.join('config/environment.rb'), /require_relative (.*)/ do |match|
          match << "\nrequire_relative '../apps/#{ opts[:slice_name] }/application'"
        end

        # Mount slice inside "Lotus::Container.configure"
        cli.gsub_file target.join('config/environment.rb'), /(mount (.*)|Lotus::Container.configure do)/ do |match|
          match << "\n  mount #{ opts[:classified_slice_name] }::Application, at: '#{ opts[:slice_base_url] }'"
        end

        ##
        # Per environment .env
        #
        ['development', 'test'].each do |environment|
          # Add WEB_DATABASE_URL="file:///db/web_development"
          cli.append_to_file target.join("config/.env.#{ environment }") do
            %(#{ opts[:upcase_slice_name] }_DATABASE_URL="file:///db/#{ opts[:slice_name] }_#{ environment }"\n)
          end

          # Add WEB_SESSIONS_SECRET="abc123" (random hex)
          cli.append_to_file target.join("config/.env.#{ environment }") do
            %(#{ opts[:upcase_slice_name] }_SESSIONS_SECRET="#{ SecureRandom.hex(32) }"\n)
          end
        end

        ##
        # New files
        #
        templates.each do |src, dst|
          cli.template(@source.join(src), @target.join(dst), opts)
        end

        ##
        # Empty directories
        #
        empty_directories.flatten.each do |dir|
          gitkeep = '.gitkeep'
          cli.template(@source.join(gitkeep), @target.join(dir, gitkeep), opts)
        end
      end
    end
  end
end
