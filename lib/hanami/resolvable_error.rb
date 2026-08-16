# frozen_string_literal: true

module Hanami
  # Lets an error describe how to fix it.
  #
  # An error that knows what went wrong usually also knows what to do about it. Include this in an
  # error class and declare one or more resolutions; the development error page renders a card for
  # each, and runs the ones that can be run.
  #
  #     class MissingCredentialError < StandardError
  #       include Hanami::ResolvableError
  #
  #       attr_reader :key
  #
  #       def initialize(key)
  #         @key = key
  #         super("#{key} is not set")
  #       end
  #
  #       resolution "Add it to .env.local" do
  #         snippet "#{key}="
  #         note "Restart the server afterwards."
  #       end
  #     end
  #
  # A resolution declaring `run` gets a button on the error page. One without it is guidance: a
  # command to copy, a snippet to paste, a list to work through. Guidance covers most of what
  # makes an error page useful and requires none of the machinery that executing code does, so
  # reach for it first and add `run` only where there is something safe to automate.
  #
  #     class NoSeedDataError < StandardError
  #       include Hanami::ResolvableError
  #
  #       resolution "Load the seed data" do
  #         command "bundle exec hanami db seed"    # what to type by hand
  #         run { |context| load context.app.root.join("config/db/seeds.rb").to_s }
  #       end
  #     end
  #
  # A resolution carrying both `run` and `command` is one fix offered two ways, not two competing
  # fixes.
  #
  # ## The underlying convention
  #
  # This module is a convenience, not a requirement. The error page reads a duck-typed convention:
  # an error is resolvable if it responds to `#resolutions`, returning objects that answer `#name`
  # and any of `#call`, `#destructive?`, `#command`, `#snippet`, `#items` and `#note`.
  #
  # Anything satisfying that is resolvable with or without this module, which is what lets gems
  # that do not depend on `hanami` offer resolutions of their own.
  #
  # @api public
  # @since 3.1.0
  module ResolvableError
    # A resolution the error page can run.
    #
    # @api public
    # @since 3.1.0
    Runnable = Struct.new(
      :name, :destructive, :command, :snippet, :items, :note, :error, :runner, keyword_init: true
    ) do
      # @api public
      # @since 3.1.0
      def destructive? = !!destructive

      # Runs against the error, so the block reads the error's own facts.
      #
      # @api public
      # @since 3.1.0
      def call(context) = error.instance_exec(context, &runner)
    end

    # A resolution that only explains.
    #
    # Deliberately defines no `#call`: that is how the error page knows not to offer a button.
    # Reporting a resolution as runnable and then having nothing to run would be worse than not
    # offering it.
    #
    # @api public
    # @since 3.1.0
    Guidance = Struct.new(:name, :command, :snippet, :items, :note, keyword_init: true)

    # @api private
    # @since 3.1.0
    Definition = Struct.new(:name, :destructive, :block, keyword_init: true)

    # Collects one resolution's content.
    #
    # Anything this does not define is forwarded to the error, so a declaration can read the
    # error's state directly even though it is written in the class body, where no instance
    # exists yet.
    #
    # @api private
    # @since 3.1.0
    class Builder
      # @api private
      # @since 3.1.0
      def initialize(error)
        @error = error
        @content = {items: []}
      end

      # @api public
      # @since 3.1.0
      def command(value) = @content[:command] = value

      # @api public
      # @since 3.1.0
      def snippet(value) = @content[:snippet] = value

      # @api public
      # @since 3.1.0
      def items(value) = @content[:items] = Array(value)

      # @api public
      # @since 3.1.0
      def note(value) = @content[:note] = value

      # Declaring this is what makes a resolution runnable.
      #
      # @api public
      # @since 3.1.0
      def run(&block) = @content[:runner] = block

      # @api private
      # @since 3.1.0
      def to_h = @content

      private

      # @api private
      # @since 3.1.0
      def method_missing(name, ...)
        return @error.public_send(name, ...) if @error.respond_to?(name)

        super
      end

      # @api private
      # @since 3.1.0
      def respond_to_missing?(name, include_private = false)
        @error.respond_to?(name) || super
      end
    end

    # @api private
    # @since 3.1.0
    module ClassMethods
      # Declares a resolution.
      #
      # The block is evaluated when the error page asks, not now, so it can read whatever the
      # error was raised with.
      #
      # @param name [String] card heading, and button label when runnable
      # @param destructive [Boolean] whether the page should require a confirming second click
      #
      # @return [Array<Definition>]
      #
      # @api public
      # @since 3.1.0
      def resolution(name, destructive: false, &block)
        resolution_definitions << Definition.new(
          name: name, destructive: destructive, block: block
        )
      end

      # @return [Array<Definition>]
      #
      # @api private
      # @since 3.1.0
      def resolution_definitions
        @resolution_definitions ||= []
      end

      # Copied rather than shared, so a subclass declaring a resolution cannot alter its parent's.
      #
      # @api private
      # @since 3.1.0
      def inherited(subclass)
        super
        subclass.instance_variable_set(:@resolution_definitions, resolution_definitions.dup)
      end
    end

    # @api private
    # @since 3.1.0
    def self.included(base)
      base.extend(ClassMethods)
    end

    # The error's resolutions, in the order they were declared.
    #
    # @return [Array<Runnable, Guidance>]
    #
    # @api public
    # @since 3.1.0
    def resolutions
      self.class.resolution_definitions.map { |definition| build_resolution(definition) }
    end

    private

    # @api private
    # @since 3.1.0
    def build_resolution(definition)
      builder = Builder.new(self)
      builder.instance_eval(&definition.block) if definition.block
      content = builder.to_h
      runner = content.delete(:runner)

      return Guidance.new(name: definition.name, **content) unless runner

      Runnable.new(
        name: definition.name, destructive: definition.destructive,
        error: self, runner: runner, **content
      )
    end
  end
end
