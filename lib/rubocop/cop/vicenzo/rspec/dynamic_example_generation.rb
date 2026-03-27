# frozen_string_literal: true

module RuboCop
  module Cop
    module Vicenzo
      module RSpec
        # Do not use iteration to dynamically generate example groups or examples.
        #
        # Dynamic generation makes tests hard to find, hard to read, and creates
        # pressure to add conditional logic (e.g. `if variable == :x`) when not
        # all iterations share the same conditions. Write explicit, static contexts
        # instead — one context per case.
        #
        # @example
        #   # bad
        #
        #   [:admin, :driver].each do |role|
        #     context "when role is #{role}" do
        #       it 'does something' do
        #         ...
        #       end
        #     end
        #   end
        #
        #   # good
        #
        #   context 'when role is admin' do
        #     let(:role) { :admin }
        #
        #     it 'does something' do
        #       ...
        #     end
        #   end
        #
        #   context 'when role is driver' do
        #     let(:role) { :driver }
        #
        #     it 'does something' do
        #       ...
        #     end
        #   end
        class DynamicExampleGeneration < RuboCop::Cop::RSpec::Base
          MSG = 'Do not use iteration to dynamically generate example groups or examples. ' \
                'Write explicit, static contexts instead.'

          ENUMERATION_METHODS = %i[each each_with_index each_with_object map flat_map].freeze

          EXAMPLE_GROUP_DSL = %i[
            context describe feature experiment
            it specify example scenario focus
            let let! subject subject! before after around
            shared_examples shared_context shared_examples_for
          ].freeze

          # @!method enumeration_block?(node)
          def_node_matcher :enumeration_block?, <<~PATTERN
            (block
              (send _ {#{ENUMERATION_METHODS.map(&:inspect).join(' ')}} ...)
              ...)
          PATTERN

          # @!method example_group_dsl_call?(node)
          def_node_matcher :example_group_dsl_call?, <<~PATTERN
            (block (send nil? {#{EXAMPLE_GROUP_DSL.map(&:inspect).join(' ')}} ...) ...)
          PATTERN

          def on_block(node)
            return unless enumeration_block?(node)
            return unless contains_example_group_dsl?(node)

            add_offense(node.send_node)
          end

          alias on_numblock on_block

          private

          def contains_example_group_dsl?(node)
            node.body&.each_node(:block) do |child|
              return true if example_group_dsl_call?(child)
            end

            false
          end
        end
      end
    end
  end
end
