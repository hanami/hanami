require 'lotus/router'
require 'lotus/controller'
require 'lotus/view'

# FIXME Ideally, this should be done like this:
#
# module Lotus
#   module Frameworks
#     module Action
#       module Rack
#         protected
#         def response
#           [super, self].flatten
#         end
#       end
#     end
#   end
# end
#
# Lotus::Action::Rack.class_eval do
#   include Lotus::Frameworks::Action::Rack
# end
#
# ..but it doesn't work and I want to ship it!

Lotus::Action::Rack.class_eval do
  DEFAULT_RESPONSE_CODE = 200
  DEFAULT_RESPONSE_BODY = []

  protected
  def response
    [ @_status || DEFAULT_RESPONSE_CODE, headers, @_body || DEFAULT_RESPONSE_BODY.dup, self ]
  end
end
