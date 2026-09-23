# frozen_string_literal: true

module RuboCop
  module Cop
    module Vicenzo
      module RSpec
        # Checks for `context` blocks with no parent scenario that start with "and", "but", or "however".
        # It suggests starting them with "when", "with", or "without" instead.
        #
        # A conjunction continues the scenario of the enclosing context. When the closest example group is
        # not a context - a `describe`, or no group at all - there is no scenario to continue, and the
        # description reads as a fragment. It usually shows up after a subtree is moved up a level: the
        # parent goes away, the titles stay as they were.
        #
        # The closest example group decides. A shared group is left alone, since the scenario it continues
        # lives where it is included.
        #
        # @example
        #   # bad
        #   describe '#available_colors' do
        #     context 'but the color pink is not available' do
        #       it 'does not show the pink option'
        #     end
        #   end
        #
        #   # good
        #   describe '#available_colors' do
        #     context 'when the color pink is not available' do
        #       it 'does not show the pink option'
        #     end
        #   end
        class UnnestedContextImproperStart < RuboCop::Cop::RSpec::Base
          MSG = 'Unnested `context` should start with `when`, `with`, or `without`, not `and`, `but`, or `however`.'

          CONTEXTS = %i[context fcontext xcontext].freeze
          FORBIDDEN_PREFIXES = %w[and but however].freeze

          # @!method context_definition?(node)
          def_node_matcher :context_definition?, <<~PATTERN
            (any_block (send nil? {#{CONTEXTS.map(&:inspect).join(' ')}} ...) ...)
          PATTERN

          def on_block(node)
            return unless context_definition?(node)
            return if continues_a_scenario?(node)

            add_offense(node.send_node) if starts_with_conjunction?(node)
          end

          alias on_numblock on_block

          private

          # A context continues its scenario, and a shared group's scenario lives where it is included, so
          # neither can be judged here.
          def continues_a_scenario?(node)
            parent = node.each_ancestor(:any_block).find { |ancestor| spec_group?(ancestor) }

            parent && (shared_group?(parent) || context_definition?(parent))
          end

          def starts_with_conjunction?(node)
            description = node.send_node.first_argument

            return false unless description&.str_type?

            FORBIDDEN_PREFIXES.include?(description.value.lstrip[/\A[[:alpha:]]+/]&.downcase)
          end
        end
      end
    end
  end
end
