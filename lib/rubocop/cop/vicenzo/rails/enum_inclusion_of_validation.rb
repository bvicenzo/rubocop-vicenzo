# frozen_string_literal: true

module RuboCop
  module Cop
    module Vicenzo
      module Rails
        # Ensures that enums using the new syntax include the
        # `validate: { allow_nil: true }` option.
        #
        # ## Bad usage
        #
        # ```ruby
        # enum :status, { active: 1, inactive: 0 }, suffix: true
        # ```
        #
        # ```ruby
        # enum :status, { active: 1, inactive: 0 }, validate: true, suffix: true
        # ```
        #
        # ## Good usage
        #
        # ```ruby
        # enum :status, { active: 1, inactive: 0 }, validate: { allow_nil: true }, suffix: true
        # ```
        #
        # This cop does not enforce validation on enums using the old syntax:
        #
        # ```ruby
        # enum status: { active: 1, inactive: 0 }
        # ```
        class EnumInclusionOfValidation < Base
          extend AutoCorrector

          MSG_MISSING_VALIDATE = 'Add `validate: { allow_nil: true }` to the enum.'
          MSG_INVALID_VALIDATE = 'The `validate` option for the enum must be `validate: { allow_nil: true }`.'

          RESTRICT_ON_SEND = [:enum].freeze

          def on_send(node)
            return unless node.command?(:enum)

            # Ignore old-style enums
            first_argument = node.first_argument
            return if first_argument&.hash_type?

            validate_kwarg = find_validate_option(node)

            register_offence_for(node, validate_kwarg)
          end
          alias on_csend on_send

          private

          def find_validate_option(enum_node)
            options_node_for(enum_node)&.each_pair&.find { |pair| pair.key.value == :validate }
          end

          def valid_validate_option?(validate_kwarg)
            validate_kwarg.value.hash_type? &&
              validate_kwarg.value.each_pair.any? do |pair|
                pair.key.value == :allow_nil && pair.value.true_type?
              end
          end

          def options_node_for(enum_node)
            enum_node.last_argument if enum_node.last_argument.hash_type?
          end

          def register_offence_for(enum_node, validate_kwarg)
            if validate_kwarg.nil?
              add_offense(enum_node, message: MSG_MISSING_VALIDATE) do |corrector|
                last_node = options_node_for(enum_node) || enum_node.last_argument
                corrector.insert_after(last_node, ', validate: { allow_nil: true }')
              end
            elsif !valid_validate_option?(validate_kwarg)
              add_offense(validate_kwarg, message: MSG_INVALID_VALIDATE) do |corrector|
                corrector.replace(validate_kwarg, 'validate: { allow_nil: true }')
              end
            end
          end
        end
      end
    end
  end
end
