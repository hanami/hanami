module Hanami
  # @api private
  module Action
    #     Developer will be able to write
    #       `render_view :show, product: @product`
    #     instead of
    #       `self.body = render_view :show, product: @product`
    #     Pros: less code, clearly, user needs to know less details
    #     Cons: slightly less explicitly, different style for actions
    # TODO: spec
    module ViewHelpers
      # @example
      #   module Web::Controllers::Products
      #     class Create
      #       include Web::Action
      #
      #       expose :product
      #
      #       params do
      #         # ...
      #       end
      #
      #       def call(params)
      #         if params.valid?
      #           # ...
      #           self.status = 201
      #           render_view :show, product: @product
      #         else
      #           self.status = 400
      #           render_view :edit
      #         end
      #       end
      #     end
      #   end
      #
      #
      # @example Other arguments
      #   # only with base exposures (format, params and csrf_token)
      #   render_view :show
      #
      #   # with all exposures
      #   render_view :show, exposures
      #
      #   # with explicit view class, custom exposures, and base exposures
      #   render_view Web::Views::Products::Show, product: @product
      def render_view(view, explicit_exposures = {})
        internal_exposures = { format: exposures[:format], params: exposures[:params], **explicit_exposures }
        internal_exposures[:csrf_token] = set_csrf_token if respond_to? :set_csrf_token

        view_klass =
          case view
          when Symbol, String then _load_view_by_key(self.class, view)
          when Class          then view
          else raise ArgumentError, 'Symbol or Class required'
          end

        self.body = view_klass.render(**internal_exposures)
      end

      # @example
      #   _load_view_by_name(Web::Controllers::Products::Create, :show) # => Web::Views::Products::Show
      #
      # @api private
      def _load_view_by_key(action_klass, view_key)
        base     = action_klass.to_s.gsub('Controllers', 'Views').split('::')
        new_tail = Hanami::Utils::String.new(view_key).classify.to_s.split('::')
        base.pop(new_tail.size)
        Hanami::Utils::Class.load! (base + new_tail).join('::')
      end
    end
  end
end
