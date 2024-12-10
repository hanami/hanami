# frozen_string_literal: true

require "hanami/cyg_utils/class_attribute"
require "hanami/cyg_utils/blank"

module Hanami
  module CygUtils
    # String inflector
    #
    # @since 0.4.1
    module Inflector # rubocop:disable Metrics/ModuleLength
      # Rules for irregular plurals
      #
      # @since 0.6.0
      # @api private
      class IrregularRules
        # @since 0.6.0
        # @api private
        def initialize(rules)
          @rules = rules
        end

        # @since 0.6.0
        # @api private
        def add(key, value)
          @rules[key.downcase] = value.downcase
        end

        # @since 0.6.0
        # @api private
        def ===(other)
          key = extract_last_alphanumeric_token(other)
          @rules.key?(key) || @rules.value?(key)
        end

        # @since 0.6.0
        # @api private
        def apply(string)
          key = extract_last_alphanumeric_token(string)
          result = @rules[key] || @rules.rassoc(key).last

          prefix = if key == string.downcase
                     string[0]
                   else
                     string[0..string.index(key)]
                   end

          prefix + result[1..-1]
        end

        private

        # @since 1.3.3
        # @api private
        def extract_last_alphanumeric_token(string)
          if string.downcase =~ /_([[:alpha:]]*)\z/
            Regexp.last_match(1)
          else
            string.downcase
          end
        end
      end

      # @since 0.4.1
      # @api private
      A    = "a"

      # @since 0.4.1
      # @api private
      CH   = "ch"

      # @since 0.4.1
      # @api private
      CHES = "ches"

      # @since 0.4.1
      # @api private
      EAUX = "eaux"

      # @since 0.6.0
      # @api private
      ES   = "es"

      # @since 0.4.1
      # @api private
      F    = "f"

      # @since 0.4.1
      # @api private
      I    = "i"

      # @since 0.4.1
      # @api private
      ICE  = "ice"

      # @since 0.4.1
      # @api private
      ICES = "ices"

      # @since 0.4.1
      # @api private
      IDES = "ides"

      # @since 0.4.1
      # @api private
      IES  = "ies"

      # @since 0.4.1
      # @api private
      IFE  = "ife"

      # @since 0.4.1
      # @api private
      IS   = "is"

      # @since 0.4.1
      # @api private
      IVES = "ives"

      # @since 0.4.1
      # @api private
      MA   = "ma"

      # @since 0.4.1
      # @api private
      MATA = "mata"

      # @since 0.4.1
      # @api private
      MEN  = "men"

      # @since 0.4.1
      # @api private
      MINA = "mina"

      # @since 0.6.0
      # @api private
      NA   = "na"

      # @since 0.6.0
      # @api private
      NON  = "non"

      # @since 0.4.1
      # @api private
      O    = "o"

      # @since 0.4.1
      # @api private
      OES  = "oes"

      # @since 0.4.1
      # @api private
      OUSE = "ouse"

      # @since 0.4.1
      # @api private
      RSE = "rse"

      # @since 0.4.1
      # @api private
      RSES = "rses"

      # @since 0.4.1
      # @api private
      S    = "s"

      # @since 0.4.1
      # @api private
      SES  = "ses"

      # @since 0.4.1
      # @api private
      SSES = "sses"

      # @since 0.6.0
      # @api private
      TA   = "ta"

      # @since 0.4.1
      # @api private
      UM   = "um"

      # @since 0.4.1
      # @api private
      US   = "us"

      # @since 0.4.1
      # @api private
      USES = "uses"

      # @since 0.4.1
      # @api private
      VES  = "ves"

      # @since 0.4.1
      # @api private
      X    = "x"

      # @since 0.4.1
      # @api private
      XES  = "xes"

      # @since 0.4.1
      # @api private
      Y    = "y"

      include CygUtils::ClassAttribute

      # Irregular rules for plurals
      #
      # @since 0.6.0
      # @api private
      class_attribute :plurals
      self.plurals = IrregularRules.new(
        # irregular
        "cactus" => "cacti",
        "child" => "children",
        "corpus" => "corpora",
        "foot" => "feet",
        "genus" => "genera",
        "goose" => "geese",
        "louse" => "lice",
        "man" => "men",
        "mouse" => "mice",
        "ox" => "oxen",
        "person" => "people",
        "quiz" => "quizzes",
        "sex" => "sexes",
        "testis" => "testes",
        "tooth" => "teeth",
        "woman" => "women",
        # uncountable
        "deer" => "deer",
        "equipment" => "equipment",
        "fish" => "fish",
        "information" => "information",
        "means" => "means",
        "money" => "money",
        "news" => "news",
        "offspring" => "offspring",
        "rice" => "rice",
        "series" => "series",
        "sheep" => "sheep",
        "species" => "species",
        "police" => "police",
        # regressions
        # https://github.com/hanami/cyg_utils/issues/106
        "album" => "albums",
        "area" => "areas"
      )

      # Irregular rules for singulars
      #
      # @since 0.6.0
      # @api private
      class_attribute :singulars
      self.singulars = IrregularRules.new(
        # irregular
        "cacti" => "cactus",
        "children" => "child",
        "corpora" => "corpus",
        "feet" => "foot",
        "genera" => "genus",
        "geese" => "goose",
        "lice" => "louse",
        "men" => "man",
        "mice" => "mouse",
        "oxen" => "ox",
        "people" => "person",
        "quizzes" => "quiz",
        "sexes" => "sex",
        "testes" => "testis",
        "teeth" => "tooth",
        "women" => "woman",
        # uncountable
        "deer" => "deer",
        "equipment" => "equipment",
        "fish" => "fish",
        "information" => "information",
        "means" => "means",
        "money" => "money",
        "news" => "news",
        "offspring" => "offspring",
        "rice" => "rice",
        "series" => "series",
        "sheep" => "sheep",
        "species" => "species",
        "police" => "police",
        # fallback
        "areas" => "area",
        "hives" => "hive",
        "phases" => "phase",
        "exercises" => "exercise",
        "releases" => "release"
      )

      # Block for custom inflection rules.
      #
      # @param [Proc] blk custom inflections
      #
      # @since 0.6.0
      #
      # @see Hanami::CygUtils::Inflector.exception
      # @see Hanami::CygUtils::Inflector.uncountable
      #
      # @example
      #   require 'hanami/cyg_utils/inflector'
      #
      #   Hanami::CygUtils::Inflector.inflections do
      #     exception   'analysis', 'analyses'
      #     exception   'alga',     'algae'
      #     uncountable 'music', 'butter'
      #   end
      def self.inflections(&blk)
        class_eval(&blk)
      end

      # Adds a custom inflection exception
      #
      # @param [String] singular form
      # @param [String] plural form
      #
      # @since 0.6.0
      #
      # @see Hanami::CygUtils::Inflector.inflections
      # @see Hanami::CygUtils::Inflector.uncountable
      #
      # @example
      #   require 'hanami/cyg_utils/inflector'
      #
      #   Hanami::CygUtils::Inflector.inflections do
      #     exception 'alga', 'algae'
      #   end
      def self.exception(singular, plural)
        add_to_inflecto(singular, plural)
        singulars.add(plural, singular)
        plurals.add(singular, plural)
      end

      # Since ROM uses Inflecto for it inferences, we need to add an exception to it
      #   when one is registered against our Inflector.
      # @api private
      def self.add_to_inflecto(singular, plural)
        return unless defined? Inflecto

        Inflecto.inflections.irregular(singular, plural)
      end

      # Adds an uncountable word
      #
      # @param [Array<String>] words
      #
      # @since 0.6.0
      #
      # @see Hanami::CygUtils::Inflector.inflections
      # @see Hanami::CygUtils::Inflector.exception
      #
      # @example
      #   require 'hanami/cyg_utils/inflector'
      #
      #   Hanami::CygUtils::Inflector.inflections do
      #     uncountable 'music', 'art'
      #   end
      def self.uncountable(*words)
        Array(words).each do |word|
          exception(word, word)
        end
      end

      # Pluralizes the given string
      #
      # @param string [String] a string to pluralize
      #
      # @return [String,NilClass] the pluralized string, if present
      #
      # @api private
      # @since 0.4.1
      #
      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Style/PerlBackrefs
      def self.pluralize(string)
        return string if string.nil? || string =~ CygUtils::Blank::STRING_MATCHER

        case string
        when plurals
          plurals.apply(string)
        when /\A((.*)[^aeiou])ch\z/
          $1 + CHES
        when /\A((.*)[^aeiou])y\z/
          $1 + IES
        when /\A(.*)(ex|ix)\z/
          $1 + ICES
        when /\A(.*)(eau|#{EAUX})\z/
          $1 + EAUX
        when /\A(.*)x\z/
          $1 + XES
        when /\A(.*)ma\z/
          string + TA
        when /\A(.*)(um|#{A})\z/
          $1 + A
        when /\A(buffal|domin|ech|embarg|her|mosquit|potat|tomat)#{O}\z/i
          $1 + OES
        when /\A(.*)(fee)\z/
          $1 + $2 + S
        when /\A(.*)(?:([^f]))f[e]*\z/
          $1 + $2 + VES
        when /\A(.*)us\z/
          $1 + USES
        when /\A(.*)non\z/
          $1 + NA
        when /\A((.*)[^aeiou])is\z/
          $1 + ES
        when /\A(.*)ss\z/
          $1 + SSES
        when /s\z/
          string
        else
          string + S
        end
      end
      # rubocop:enable Style/PerlBackrefs
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/CyclomaticComplexity

      # Singularizes the given string
      #
      # @param string [String] a string to singularize
      #
      # @return [String,NilClass] the singularized string, if present
      #
      # @api private
      # @since 0.4.1
      #
      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      # rubocop:disable Style/PerlBackrefs
      def self.singularize(string)
        return string if string.nil? || string =~ CygUtils::Blank::STRING_MATCHER

        case string
        when singulars
          singulars.apply(string)
        when /\A.*[^aeiou]#{CHES}\z/
          string.sub(CHES, CH)
        when /\A.*[^aeiou]#{IES}\z/
          string.sub(IES, Y)
        when /\A.*#{EAUX}\z/
          string.chop
        when /\A(.*)#{IDES}\z/
          $1 + IS
        when /\A(.*)#{US}\z/
          $1 + I
        when /\A(.*)#{RSES}\z/
          $1 + RSE
        when /\A(.*)#{SES}\z/
          $1 + S
        when /\A(.*)#{MATA}\z/
          $1 + MA
        when /\A(.*)#{OES}\z/
          $1 + O
        when /\A(.*)#{MINA}\z/
          $1 + MEN
        when /\A(.*)#{XES}\z/
          $1 + X
        when /\A(.*)#{IVES}\z/
          $1 + IFE
        when /\A(.*)#{VES}\z/
          $1 + F
        when /\A(.*)#{I}\z/
          $1 + US
        when /\A(.*)ae\z/
          $1 + A
        when /\A(.*)na\z/
          $1 + NON
        when /\A(.*)#{A}\z/
          $1 + UM
        when /[^s]\z/
          string
        else
          string.chop
        end
      end
      # rubocop:enable Style/PerlBackrefs
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/CyclomaticComplexity

      # rubocop:enable Metrics/PerceivedComplexity
    end
  end
end
