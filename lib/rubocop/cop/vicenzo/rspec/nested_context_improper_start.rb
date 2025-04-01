# frozen_string_literal: true

module RuboCop
  module Cop
    module Vicenzo
      module RSpec
        # Checks for nested `context` blocks where the inner `context`
        # starts with "when", "with", or "without". It suggests replacing it with "and", "but", or "however".
        #
        # @example
        #   # bad
        #   context 'when the product is for sale' do
        #     context 'when the color pink is not available' do
        #       it 'does not show the pink option'
        #     end
        #   end
        #
        #   # good
        #   context 'when the product is for sale' do
        #     context 'but the color pink is not available' do
        #       it 'does not show the pink option'
        #     end
        #   end
        class NestedContextImproperStart < Base
          MSG = 'Nested `context` should start with `and`, `but`, or `however`, not `when`, `with`, or `without`.'
          INVALID_PREFIXES = %w[when with without].freeze

          def on_block(node)
            return unless context_with_string?(node)

            parent = node.parent
            return unless parent&.block_type? && context_with_string?(parent)

            inner_context, = *node.send_node.arguments
            return unless inner_context.str_type? && starts_with_invalid_prefix?(inner_context.value)

            add_offense(inner_context)
          end

          alias on_numblock on_block

          private

          def context_with_string?(node)
            return false unless node.block_type?

            send_node = node.send_node
            return false unless send_node&.send_type? && send_node.method?(:context)

            first_argument, = *send_node.arguments
            first_argument&.str_type?
          end

          def starts_with_invalid_prefix?(value)
            INVALID_PREFIXES.any? { |prefix| value.match?(/^#{prefix} /i) }
          end
        end
      end
    end
  end
end
