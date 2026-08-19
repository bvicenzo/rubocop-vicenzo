# frozen_string_literal: true

require_relative 'mixin/premise_tracking'

module RuboCop
  module Cop
    module Vicenzo
      module RSpec
        # Do not derive a premise from another premise.
        #
        # `let(:params) { base_params.merge(age: 10) }` does not mutate anything, but it splits a single premise
        # across two definitions: to know what `params` holds in a context you have to read another `let` — usually
        # one that exists only to be modified. Declare the complete value in the context that needs it.
        #
        # Only premise definitions (`let`, `let_it_be`, `subject`) are inspected, and only when the copy starts from
        # another premise: deriving from a factory or from a literal is untouched.
        #
        # @example
        #   # bad
        #
        #   let(:base_params) { { name: 'Ada' } }
        #   let(:params) { base_params.merge(age: 10) }
        #
        #   # good
        #
        #   context 'when the age is informed' do
        #     let(:params) { { name: 'Ada', age: 10 } }
        #   end
        #
        #   context 'when the age is unknown' do
        #     let(:params) { { name: 'Ada' } }
        #   end
        #
        # @example
        #   # good — the source is a factory, not another premise
        #
        #   let(:params) { attributes_for(:order).merge(value: 10) }
        class DerivedPremises < RuboCop::Cop::RSpec::Base
          include PremiseTracking

          MSG = 'Do not derive the premise `%<name>s` from `%<source>s`. ' \
                'Declare the complete value in the context that needs it.'

          DERIVING_METHODS = %i[merge deep_merge reverse_merge dup clone except slice].freeze

          def on_block(node)
            return unless example_group?(node) && outermost_example_group?(node)

            walk_example_group(node, all_premises(node))
          end

          alias on_numblock on_block

          private

          def on_premise(node, premises)
            name = premise_name(node)

            mutating_calls(node).each do |call|
              next unless DERIVING_METHODS.include?(call.method_name)

              source = premise_receiver(call, premises)

              next if source.nil?

              add_offense(call, message: format(MSG, name:, source:))
            end
          end

          def on_setup_hook(node, premises); end
        end
      end
    end
  end
end
