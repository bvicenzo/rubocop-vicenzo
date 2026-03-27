# frozen_string_literal: true

module RuboCop
  module Cop
    module Vicenzo
      module RSpec
        # Do not use conditional logic in spec files.
        #
        # Any `if`, `unless`, or ternary expression in a spec represents a hidden
        # context. Each branch should be an explicit `context` block so that the
        # conditions and expectations are always clear and unconditional.
        #
        # @example
        #   # bad — hidden context inside an example
        #
        #   it 'grants or denies access' do
        #     if user.admin?
        #       expect(result).to eq(:granted)
        #     else
        #       expect(result).to eq(:denied)
        #     end
        #   end
        #
        #   # bad — hidden context inside a let
        #
        #   let(:user) { admin? ? create(:admin) : create(:client) }
        #
        #   # bad — hidden context inside a before hook
        #
        #   before { setup_thing if feature_enabled? }
        #
        #   # bad — hidden context at the example group level using unless
        #
        #   unless legacy_mode?
        #     it 'uses the new behaviour' do
        #       ...
        #     end
        #   end
        #
        #   # good
        #
        #   context 'when user is admin' do
        #     let(:user) { create(:admin) }
        #
        #     it 'grants access' do
        #       expect(result).to eq(:granted)
        #     end
        #   end
        #
        #   context 'when user is not admin' do
        #     let(:user) { create(:client) }
        #
        #     it 'denies access' do
        #       expect(result).to eq(:denied)
        #     end
        #   end
        class ConditionalInSpec < RuboCop::Cop::RSpec::Base
          MSG = 'Do not use conditional logic in specs. ' \
                'Extract each branch into an explicit context instead.'

          # Both `if` and `unless` are represented as `if` nodes in the AST,
          # so this single hook covers all conditional forms: `if`, `unless`,
          # modifier `if`/`unless`, and ternary `?:`.
          def on_if(node)
            offense_location = node.ternary? ? node : node.loc.keyword
            add_offense(offense_location)
          end
        end
      end
    end
  end
end
