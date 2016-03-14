require 'rack'
require 'hanami/server'

module Hanami
  module Commands
    class Server

      # Message text when Shotgun enabled but interpreter does not support `fork`
      #
      # @since 0.8.0
      # @api private
      WARNING_MESSAGE = 'Your platform doesn\'t support code reloading.'.freeze

      ENTR_EXECUTE_COMMAND = "find %{paths} -type f | entr -r bundle exec hanami rackserver %{args}".freeze

      attr_reader :server

      def initialize(options)
        @options = options
        detect_strategy!
        prepare_server!
      end

      def start
        case @strategy
        when :entr
          exec ENTR_EXECUTE_COMMAND % {paths: project_paths, args: server_options}
        when :shotgun
          Shotgun.enable_copy_on_write
          Shotgun.preload
          @server.start
        when :rackup
          @server.start
        end
      end

      private

      def server_options
        _options = @options.dup
        _options.delete(:code_reloading)
        _options.inject([]) {|res, (k, v)| res << "--#{k}=#{v}" ; res}.join(" ")
      end

      def project_paths
        applications = Hanami::Environment.new.container? ? 'apps' : 'app'
        "#{ applications } config db lib"
      end

      def prepare_server!
        case @strategy
        when :rackup
          @server = Hanami::Server.new(@options)
        when :shotgun
          @server = Hanami::Server.new(@options)
          @server.app = Shotgun::Loader.new(@server.rackup_config)
        end
      end

      # Determine server strategy
      #
      # In order to decide the value, it looks up the following sources:
      #
      #   * CLI option `code_reloading`
      #
      # If those are missing it falls back to the following defaults:
      #
      #   * :shotgun for development and if Shotgun enabled and `fork supported
      #   * :entr for development and Shotgun disabled but `entr` installed
      #   * :rackup for all other cases
      #
      # @return [:shotgun,:entr, :rackup] the result of the check
      #
      # @since 0.8.0
      #
      # @see Hanami::Environment::CODE_RELOADING
      def detect_strategy!
        @strategy = :rackup
        if Hanami::Environment.new(@options).code_reloading?
          if shotgun_enabled?
            if fork_supported?
              @strategy = :shotgun
            else
              puts WARNING_MESSAGE
            end
          elsif entr_enabled?
            @strategy = :entr
          end
        end

        @strategy
      end

      # Check if entr(1) is installed
      #
      # @return [Boolean]
      #
      # @since 0.8.0
      # @api private
      def entr_enabled?
        !!which('entr')
      end


      # Check if Shotgun is enabled
      #
      # @return [Boolean]
      #
      # @since 0.8.0
      # @api private
      def shotgun_enabled?
        begin
        require 'shotgun'
        true
        rescue LoadError
          false
        end
      end

      # Check if ruby ineterpreter supports `fork`
      #
      # @return [Boolean]
      #
      # @since 0.8.0
      # @api private
      def fork_supported?
        Kernel.respond_to?(:fork)
      end

      # Cross-platform way of finding an executable in the $PATH.
      #
      # Usage:
      #   which('ruby') #=> /usr/bin/ruby
      #
      # @since 0.8.0
      # @api private
      def which(cmd)
        exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
        ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
          exts.each { |ext|
            exe = File.join(path, "#{cmd}#{ext}")
            return exe if File.executable?(exe) && !File.directory?(exe)
          }
        end
        return nil
      end
    end
  end
end
