# frozen_string_literal: true

module Hanami
  module Extensions
    module Action
      # Action translation and localization helpers.
      #
      # These helpers are automatically available on `Hanami::Action` when the `i18n` gem is
      # bundled.
      #
      # When relative translation keys (with a leading dot) are given, they are expanded against a
      # the action's name. For example, `t(".not_found")` within `Main::Actions::Posts::Show`
      # becomes `"posts.show.not_found"`.
      #
      # @example Basic translation in an action
      #   module Main
      #     module Actions
      #       module Posts
      #         class Create < Main::Action
      #           def handle(req, res)
      #             res.flash[:notice] = t("messages.post_created")
      #             res.redirect_to routes.path(:posts)
      #           end
      #         end
      #       end
      #     end
      #   end
      #
      # @example Relative key lookup
      #   # In Main::Actions::Posts::Show, this looks up "posts.show.not_found"
      #   t(".not_found")
      #
      # @see Hanami::Helpers::I18nHelper::Methods
      #
      # @api public
      # @since 3.0.0
      module I18nHelper
        include Hanami::Helpers::I18nHelper::Methods

        private

        def _i18n
          i18n
        end

        def _resolve_i18n_key(key)
          return key unless key.to_s.start_with?(".")

          key_base = self.class.config.i18n_key_base

          unless key_base
            raise(
              ::I18n::ArgumentError,
              "Cannot use relative translation key #{key.inspect} outside of a slice-configured action. " \
              "Use an absolute key (without a leading dot) instead."
            )
          end

          "#{key_base}#{key}"
        end
      end
    end
  end
end
