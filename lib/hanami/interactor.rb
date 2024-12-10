# frozen_string_literal: true

require "hanami/cyg_utils/basic_object"
require "hanami/cyg_utils/class_attribute"
require "hanami/cyg_utils/hash"

module Hanami
  # Hanami Interactor
  #
  # @since 0.3.5
  module Interactor
    # Result of an operation
    #
    # @since 0.3.5
    class Result < CygUtils::BasicObject
      # Concrete methods
      #
      # @since 0.3.5
      # @api private
      #
      # @see Hanami::Interactor::Result#respond_to_missing?
      METHODS = ::Hash[initialize: true,
                       success?: true,
                       successful?: true,
                       failure?: true,
                       fail!: true,
                       prepare!: true,
                       errors: true,
                       error: true].freeze

      # Initialize a new result
      #
      # @param payload [Hash] a payload to carry on
      #
      # @return [Hanami::Interactor::Result]
      #
      # @since 0.3.5
      # @api private
      def initialize(payload = {})
        @payload = payload
        @errors  = []
        @success = true
      end

      # Checks if the current status is successful
      #
      # @return [TrueClass,FalseClass] the result of the check
      #
      # @since 0.8.1
      def successful?
        @success && errors.empty?
      end

      # @since 0.3.5
      alias_method :success?, :successful?

      # Checks if the current status is not successful
      #
      # @return [TrueClass,FalseClass] the result of the check
      #
      # @since 0.9.2
      def failure?
        !successful?
      end

      # Forces the status to be a failure
      #
      # @since 0.3.5
      def fail!
        @success = false
      end

      # Returns all the errors collected during an operation
      #
      # @return [Array] the errors
      #
      # @since 0.3.5
      #
      # @see Hanami::Interactor::Result#error
      # @see Hanami::Interactor#call
      # @see Hanami::Interactor#error
      # @see Hanami::Interactor#error!
      def errors
        @errors.dup
      end

      # @since 0.5.0
      # @api private
      def add_error(*errors)
        @errors << errors
        @errors.flatten!
        nil
      end

      # Returns the first errors collected during an operation
      #
      # @return [nil,String] the error, if present
      #
      # @since 0.3.5
      #
      # @see Hanami::Interactor::Result#errors
      # @see Hanami::Interactor#call
      # @see Hanami::Interactor#error
      # @see Hanami::Interactor#error!
      def error
        errors.first
      end

      # Prepares the result before to be returned
      #
      # @param payload [Hash] an updated payload
      #
      # @since 0.3.5
      # @api private
      def prepare!(payload)
        @payload.merge!(payload)
        self
      end

      protected

      # @since 0.3.5
      # @api private
      def method_missing(method_name, *)
        @payload.fetch(method_name) { super }
      end

      # @since 0.3.5
      # @api private
      def respond_to_missing?(method_name, _include_all)
        method_name = method_name.to_sym
        METHODS[method_name] || @payload.key?(method_name)
      end

      # @since 0.3.5
      # @api private
      def __inspect
        " @success=#{@success} @payload=#{@payload.inspect}"
      end
    end

    # Override for <tt>Module#included</tt>.
    #
    # @since 0.3.5
    # @api private
    def self.included(base)
      super

      base.class_eval do
        extend ClassMethods
      end
    end

    # Interactor legacy interface
    #
    # @since 0.3.5
    module LegacyInterface
      # Initialize an interactor
      #
      # It accepts arbitrary number of arguments.
      # Developers can override it.
      #
      # @param args [Array<Object>] arbitrary number of arguments
      #
      # @return [Hanami::Interactor] the interactor
      #
      # @since 0.3.5
      #
      # @example Override #initialize
      #   require 'hanami/interactor'
      #
      #   class UpdateProfile
      #     include Hanami::Interactor
      #
      #     def initialize(user, params)
      #       @user   = user
      #       @params = params
      #     end
      #
      #     def call
      #       # ...
      #     end
      #   end
      if RUBY_VERSION >= "3.0"
        def initialize(*args, **kwargs)
          super
        ensure
          @__result = ::Hanami::Interactor::Result.new
        end
      else
        def initialize(*args)
          super
        ensure
          @__result = ::Hanami::Interactor::Result.new
        end
      end

      # Triggers the operation and return a result.
      #
      # All the instance variables will be available in the result.
      #
      # ATTENTION: This must be implemented by the including class.
      #
      # @return [Hanami::Interactor::Result] the result of the operation
      #
      # @raise [NoMethodError] if this isn't implemented by the including class.
      #
      # @example Expose instance variables in result payload
      #   require 'hanami/interactor'
      #
      #   class Signup
      #     include Hanami::Interactor
      #     expose :user, :params
      #
      #     def initialize(params)
      #       @params = params
      #       @foo    = 'bar'
      #     end
      #
      #     def call
      #       @user = UserRepository.new.create(@params)
      #     end
      #   end
      #
      #   result = Signup.new(name: 'Luca').call
      #   result.failure? # => false
      #   result.successful? # => true
      #
      #   result.user   # => #<User:0x007fa311105778 @id=1 @name="Luca">
      #   result.params # => { :name=>"Luca" }
      #   result.foo    # => raises NoMethodError
      #
      # @example Failed precondition
      #   require 'hanami/interactor'
      #
      #   class Signup
      #     include Hanami::Interactor
      #     expose :user
      #
      #     def initialize(params)
      #       @params = params
      #     end
      #
      #     # THIS WON'T BE INVOKED BECAUSE #valid? WILL RETURN false
      #     def call
      #       @user = UserRepository.new.create(@params)
      #     end
      #
      #     private
      #     def valid?
      #       @params.valid?
      #     end
      #   end
      #
      #   result = Signup.new(name: nil).call
      #   result.successful? # => false
      #   result.failure? # => true
      #
      #   result.user   # => #<User:0x007fa311105778 @id=nil @name="Luca">
      #
      # @example Bad usage
      #   require 'hanami/interactor'
      #
      #   class Signup
      #     include Hanami::Interactor
      #
      #     # Method #call is not defined
      #   end
      #
      #   Signup.new.call # => NoMethodError
      def call
        _call { super }
      end

      private

      # @since 0.3.5
      # @api private
      def _call
        catch :fail do
          validate!
          yield
        end

        _prepare!
      end

      # @since 0.3.5
      def validate!
        fail! unless valid?
      end
    end

    # Interactor interface
    # @since 1.1.0
    module Interface
      # Triggers the operation and return a result.
      #
      # All the exposed instance variables will be available in the result.
      #
      # ATTENTION: This must be implemented by the including class.
      #
      # @return [Hanami::Interactor::Result] the result of the operation
      #
      # @raise [NoMethodError] if this isn't implemented by the including class.
      #
      # @example Expose instance variables in result payload
      #   require 'hanami/interactor'
      #
      #   class Signup
      #     include Hanami::Interactor
      #     expose :user, :params
      #
      #     def call(params)
      #       @params = params
      #       @foo = 'bar'
      #       @user = UserRepository.new.persist(User.new(params))
      #     end
      #   end
      #
      #   result = Signup.new(name: 'Luca').call
      #   result.failure? # => false
      #   result.successful? # => true
      #
      #   result.user   # => #<User:0x007fa311105778 @id=1 @name="Luca">
      #   result.params # => { :name=>"Luca" }
      #   result.foo    # => raises NoMethodError
      #
      # @example Failed precondition
      #   require 'hanami/interactor'
      #
      #   class Signup
      #     include Hanami::Interactor
      #     expose :user
      #
      #     # THIS WON'T BE INVOKED BECAUSE #valid? WILL RETURN false
      #     def call(params)
      #       @user = User.new(params)
      #       @user = UserRepository.new.persist(@user)
      #     end
      #
      #     private
      #     def valid?(params)
      #       params.valid?
      #     end
      #   end
      #
      #   result = Signup.new.call(name: nil)
      #   result.successful? # => false
      #   result.failure? # => true
      #
      #   result.user   # => nil
      #
      # @example Bad usage
      #   require 'hanami/interactor'
      #
      #   class Signup
      #     include Hanami::Interactor
      #
      #     # Method #call is not defined
      #   end
      #
      #   Signup.new.call # => NoMethodError
      if RUBY_VERSION >= "3.0"
        def call(*args, **kwargs)
          @__result = ::Hanami::Interactor::Result.new
          _call(*args, **kwargs) { super }
        end
      else
        def call(*args)
          @__result = ::Hanami::Interactor::Result.new
          _call(*args) { super }
        end
      end

      private

      # @api private
      # @since 1.1.0
      if RUBY_VERSION >= "3.0"
        def _call(*args, **kwargs)
          catch :fail do
            validate!(*args, **kwargs)
            yield
          end

          _prepare!
        end
      else
        def _call(*args)
          catch :fail do
            validate!(*args)
            yield
          end

          _prepare!
        end
      end

      # @since 1.1.0
      if RUBY_VERSION >= "3.0"
        def validate!(*args, **kwargs)
          fail! unless valid?(*args, **kwargs)
        end
      else
        def validate!(*args)
          fail! unless valid?(*args)
        end
      end
    end

    private

    # Checks if proceed with <tt>#call</tt> invocation.
    # By default it returns <tt>true</tt>.
    #
    # Developers can override it.
    #
    # @return [TrueClass,FalseClass] the result of the check
    #
    # @since 0.3.5
    def valid?(*)
      true
    end

    # Fails and interrupts the current flow.
    #
    # @since 0.3.5
    #
    # @example
    #   require 'hanami/interactor'
    #
    #   class CreateEmailTest
    #     include Hanami::Interactor
    #
    #     def initialize(params)
    #       @params     = params
    #     end
    #
    #     def call
    #       persist_email_test!
    #       capture_screenshot!
    #     end
    #
    #     private
    #     def persist_email_test!
    #       @email_test = EmailTestRepository.new.create(@params)
    #     end
    #
    #     # IF THIS RAISES AN EXCEPTION WE FORCE A FAILURE
    #     def capture_screenshot!
    #       Screenshot.new(@email_test).capture!
    #     rescue
    #       fail!
    #     end
    #   end
    #
    #   result = CreateEmailTest.new(account_id: 1).call
    #   result.successful? # => false
    def fail!
      @__result.fail!
      throw :fail
    end

    # Logs an error without interrupting the flow.
    #
    # When used, the returned result won't be successful.
    #
    # @param message [String] the error message
    #
    # @return false
    #
    # @since 0.3.5
    #
    # @see Hanami::Interactor#error!
    #
    # @example
    #   require 'hanami/interactor'
    #
    #   class CreateRecord
    #     include Hanami::Interactor
    #     expose :logger
    #
    #     def initialize
    #       @logger = []
    #     end
    #
    #     def call
    #       prepare_data!
    #       persist!
    #       sync!
    #     end
    #
    #     private
    #     def prepare_data!
    #       @logger << __method__
    #       error "Prepare data error"
    #     end
    #
    #     def persist!
    #       @logger << __method__
    #       error "Persist error"
    #     end
    #
    #     def sync!
    #       @logger << __method__
    #     end
    #   end
    #
    #   result = CreateRecord.new.call
    #   result.successful? # => false
    #
    #   result.errors # => ["Prepare data error", "Persist error"]
    #   result.logger # => [:prepare_data!, :persist!, :sync!]
    def error(message)
      @__result.add_error message
      false
    end

    # Logs an error and interrupts the flow.
    #
    # When used, the returned result won't be successful.
    #
    # @param message [String] the error message
    #
    # @since 0.3.5
    #
    # @see Hanami::Interactor#error
    #
    # @example
    #   require 'hanami/interactor'
    #
    #   class CreateRecord
    #     include Hanami::Interactor
    #     expose :logger
    #
    #     def initialize
    #       @logger = []
    #     end
    #
    #     def call
    #       prepare_data!
    #       persist!
    #       sync!
    #     end
    #
    #     private
    #     def prepare_data!
    #       @logger << __method__
    #       error "Prepare data error"
    #     end
    #
    #     def persist!
    #       @logger << __method__
    #       error! "Persist error"
    #     end
    #
    #     # THIS WILL NEVER BE INVOKED BECAUSE WE USE #error! IN #persist!
    #     def sync!
    #       @logger << __method__
    #     end
    #   end
    #
    #   result = CreateRecord.new.call
    #   result.successful? # => false
    #
    #   result.errors # => ["Prepare data error", "Persist error"]
    #   result.logger # => [:prepare_data!, :persist!]
    def error!(message)
      error(message)
      fail!
    end

    # @since 0.3.5
    # @api private
    def _prepare!
      @__result.prepare!(_exposures)
    end

    # @since 0.5.0
    # @api private
    def _exposures
      Hash[].tap do |result|
        self.class.exposures.each do |name, ivar|
          result[name] = instance_variable_defined?(ivar) ? instance_variable_get(ivar) : nil
        end
      end
    end
  end

  # @since 0.5.0
  # @api private
  module ClassMethods
    # @since 0.5.0
    # @api private
    def self.extended(interactor)
      interactor.class_eval do
        include CygUtils::ClassAttribute

        class_attribute :exposures
        self.exposures = {}
      end
    end

    def method_added(method_name)
      super
      return unless method_name == :call

      if instance_method(:call).arity.zero?
        prepend Hanami::Interactor::LegacyInterface
      else
        prepend Hanami::Interactor::Interface
      end
    end

    # Exposes local instance variables into the returning value of <tt>#call</tt>
    #
    # @param instance_variable_names [Symbol,Array<Symbol>] one or more instance
    #   variable names
    #
    # @since 0.5.0
    #
    # @see Hanami::Interactor::Result
    #
    # @example Exposes instance variable
    #
    #   class Signup
    #     include Hanami::Interactor
    #     expose :user
    #
    #     def initialize(params)
    #       @params = params
    #       @user   = User.new(@params[:user])
    #     end
    #
    #     def call
    #       # ...
    #     end
    #   end
    #
    #   result = Signup.new(user: { name: "Luca" }).call
    #
    #   result.user   # => #<User:0x007fa85c58ccd8 @name="Luca">
    #   result.params # => NoMethodError
    def expose(*instance_variable_names)
      instance_variable_names.each do |name|
        exposures[name.to_sym] = "@#{name}"
      end
    end
  end
end
