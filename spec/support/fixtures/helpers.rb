# frozen_string_literal: true

require "hanami/helpers/form_helper"
require "hanami/action/base_params"
require "dry/types"
require "dry/struct"

module Types
  include Dry.Types(default: :nominal)
end

class FormHelperView
  include Hanami::Helpers::FormHelper
  attr_reader :params

  def initialize(params)
    @params = _build_params(params)
  end

  def locals
    {params: params}
  end

  private

  def _build_params(params)
    parameters = params.to_h

    # Randomly use Hanami::Action::BaseParams or the given raw Hash in order to
    # simulate Hash usage during the spec setup of unit specs in Hanami projects.
    if parameters.respond_to?(:dig)
      [true, false].sample ? Hanami::Action::BaseParams.new(parameters) : parameters
    else
      Hanami::Action::BaseParams.new(parameters)
    end
  end
end

class SessionFormHelperView < FormHelperView
  def initialize(params, csrf_token)
    super(params)
    @csrf_token = csrf_token
  end

  def session
    {_csrf_token: @csrf_token}
  end
end

class HashSerializable
  def initialize(data)
    @data = data
  end

  def to_hash
    @data
  end
end

class Signup < Dry::Struct
  attribute :password, Types::String.optional
end

class Book < Dry::Struct
  transform_keys(&:to_sym)
  transform_types(&:omittable)

  attribute :title,               Types::String.optional
  attribute :search_title,        Types::String.optional
  attribute :description,         Types::String.optional
  attribute :author_id,           Types::Params::Integer.optional
  attribute :category,            Types::String.optional
  attribute :cover,               Types::String.optional
  attribute :image_cover,         Types::String.optional
  attribute :percent_read,        Types::Params::Integer.optional
  attribute :discount_percentage, Types::Params::Integer.optional
  attribute :published_at,        Types::String.optional
  attribute :website,             Types::String.optional
  attribute :publisher_email,     Types::String.optional
  attribute :publisher_telephone, Types::String.optional
  attribute :release_date,        Types::Params::Date.optional
  attribute :release_hour,        Types::String.optional
  attribute :release_week,        Types::String.optional
  attribute :release_month,       Types::String.optional
  attribute :store,               Types::String.optional
end
