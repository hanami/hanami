# frozen_string_literal: true

module Hanami
  class Configuration
    # Hanami configuration for views
    #
    # @since 2.0.0
    class Views
      attr_reader :options

      def initialize(options = {})
        @options = options
      end

      def base_path
        options[:base_path] || "views"
      end

      def base_path=(path)
        options[:base_path] = path
      end

      def templates_path
        options[:templates_path] || "web/templates"
      end

      def templates_path=(path)
        options[:templates_path] = path
      end

      def layouts_dir
        options[:layouts_dir]
      end

      def layouts_dir=(dir)
        options[:layouts_dir] = dir
      end

      def default_layout
        options[:default_layout] || "application"
      end

      def default_layout=(name)
        options[:default_layout] = name
      end
    end
  end
end
