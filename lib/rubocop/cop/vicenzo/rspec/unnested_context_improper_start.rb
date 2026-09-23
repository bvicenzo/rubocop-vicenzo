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
        # The words that continue a scenario come from `ForbiddenPrefixes`, compared against the first word
        # of the description, ignoring case. Setting it replaces the defaults; to add words to them, declare
        # `inherit_mode: { merge: [ForbiddenPrefixes] }` for the cop.
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
        #
        # @example ForbiddenPrefixes: ['and', 'but', 'however', 'also']
        #   # bad
        #   describe '#available_colors' do
        #     context 'also when the color pink is not available' do
        #       it 'does not show the pink option'
        #     end
        #   end
        class UnnestedContextImproperStart < RuboCop::Cop::RSpec::Base
          MSG = 'Unnested `context` should start with `when`, `with`, or `without`, not `%<prefix>s`.'

          CONTEXTS = %i[context fcontext xcontext].freeze
          DEFAULT_FORBIDDEN_PREFIXES = %w[and but however].freeze

          # @!method context_definition?(node)
          def_node_matcher :context_definition?, <<~PATTERN
            (any_block (send nil? {#{CONTEXTS.map(&:inspect).join(' ')}} ...) ...)
          PATTERN

          def on_block(node)
            return unless context_definition?(node)
            return if continues_a_scenario?(node)

            prefix = first_word(node)

            add_offense(node.send_node, message: format(MSG, prefix:)) if forbidden_prefixes.include?(prefix)
          end

          alias on_numblock on_block

          private

          # A context continues its scenario, and a shared group's scenario lives where it is included, so
          # neither can be judged here.
          def continues_a_scenario?(node)
            parent = node.each_ancestor(:any_block).find { |ancestor| spec_group?(ancestor) }

            parent && (shared_group?(parent) || context_definition?(parent))
          end

          def first_word(node)
            description = node.send_node.first_argument

            description.value.lstrip[/\A[[:alpha:]]+/]&.downcase if description&.str_type?
          end

          def forbidden_prefixes
            cop_config.fetch('ForbiddenPrefixes', DEFAULT_FORBIDDEN_PREFIXES).map(&:downcase)
          end
        end
      end
    end
  end
end
