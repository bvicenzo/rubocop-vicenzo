# frozen_string_literal: true

module RuboCop
  module Cop
    module Vicenzo
      module RSpec
        # Ensures that examples (`it`, `specify`, `example`)
        # are not mixed with groups (`describe`, `context`) at the same level.
        #
        # @example
        #   # bad
        #   RSpec.describe User do
        #     it { is_expected.to validate_presence_of(:name) }
        #     describe '#admin?' do
        #       it { expect(true).to eq(true) }
        #     end
        #   end
        #
        #   # bad
        #   RSpec.describe User do
        #     describe '#admin?' do
        #       it { expect(true).to eq(true) }
        #       context 'when email starts with' do
        #       end
        #     end
        #   end
        #
        #   # good
        #   RSpec.describe User do
        #     describe '#admin?' do
        #       context 'when email starts with' do
        #         it { expect(true).to eq(true) }
        #       end
        #     end
        #   end
        class MixedExampleGroups < RuboCop::Cop::RSpec::Base
          MSG = 'Do not mix examples (`it`, `specify`, `example`) with groups (`describe`, `context`) ' \
                'at the same level.'

          def on_block(node)
            return unless example_or_group?(node)

            parent = node.parent
            return unless parent

            children = parent.children.select { |child| example_or_group?(child) }
            example_nodes, group_nodes = children.partition { |n| example?(n) }

            return if example_nodes.empty? || group_nodes.empty?

            add_offense(node)
          end

          alias on_numblock on_block

          private

          def example_or_group?(node)
            example?(node) || example_group?(node)
          end
        end
      end
    end
  end
end
