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

          def_node_matcher :context_block?, <<~PATTERN
            (block (send nil? :context ...) ...)
          PATTERN

          def_node_matcher :example_group_block?, <<~PATTERN
            (block (send nil? {:describe :context :feature :example_group} ...) ...)
          PATTERN

          def on_block(node)
            return unless context_block?(node)

            parent = find_closest_example_group(node)

            return unless parent && context_block?(parent)

            check_description(node)
          end

          alias on_numblock on_block

          private

          def find_closest_example_group(node)
            node.each_ancestor(:block).find { |ancestor| example_group_block?(ancestor) }
          end

          def check_description(node)
            description_node = node.send_node.first_argument

            return unless description_node&.str_type?

            text = description_node.value.to_s.strip
            first_word = text.split.first&.downcase

            if FORBIDDEN_PREFIXES.include?(first_word)
              add_offense(node.send_node)
            end
          end
        end
      end
    end
  end
end
