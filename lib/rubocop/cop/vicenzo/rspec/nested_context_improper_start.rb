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
        class NestedContextImproperStart < RuboCop::Cop::RSpec::Base
          MSG = 'Nested `context` should start with `and`, `but`, or `however`, not `when`, `with`, or `without`.'

          FORBIDDEN_PREFIXES = %w[when with without].freeze

          def on_block(node)
            return unless context_block?(node) && context_block?(node.parent)

            context_description = description_for(node)
            return unless context_description

            first_word = context_description.split.first&.downcase
            return unless FORBIDDEN_PREFIXES.include?(first_word)

            add_offense(node.send_node)
          end

          alias on_numblock on_block

          private

          def context_block?(node)
            !node.nil? && node.block_type? && node.send_node.command?(:context)
          end

          def description_for(context_node)
            description = context_node.send_node.first_argument

            return if description.nil?

            description.source.delete_prefix("'").delete_suffix("'")
          end
        end
      end
    end
  end
end
