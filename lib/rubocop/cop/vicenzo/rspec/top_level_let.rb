# frozen_string_literal: true

require_relative 'mixin/top_level_definition'

module RuboCop
  module Cop
    module Vicenzo
      module RSpec
        # A let declared straight inside the top-level example group is the root of the nested
        # redefinition problem. Declare it in the group whose examples read it.
        #
        # The top-level group is the widest scope a file has: a let born there is handed to every
        # example, including all the ones written later that were never considered when it was written.
        # The first sibling group that needs the value to be slightly different has nowhere to go but
        # over the top of it - a redefinition, a near-copy under another name, or a `before` that mutates
        # the value back into shape. None of those read as a specification any more, and each one is a
        # scenario nobody named.
        #
        # Declaring the let in the group that reads it costs one extra line per group and buys back the
        # naming: each group states the premises its examples start from, and a sibling that starts from
        # a different value is a different group with its own declaration, not an override of someone
        # else's.
        #
        # This is the preventive half of `Vicenzo/RSpec/NestedLetRedefinition`, which reports the
        # redefinition once it exists. Keeping the top-level group free of lets means there is nothing to
        # redefine.
        #
        # @example
        #   # bad - the let reaches every example, so `#adult?` can only override it
        #   RSpec.describe Person do
        #     let(:age) { 42 }
        #
        #     describe '#tall?' do
        #       it { is_expected.to be_tall }
        #     end
        #
        #     describe '#adult?' do
        #       let(:age) { 17 }
        #
        #       it { is_expected.not_to be_adult }
        #     end
        #   end
        #
        #   # good - each group declares the premises its examples start from
        #   RSpec.describe Person do
        #     describe '#tall?' do
        #       subject(:person) { described_class.new(height: 1.75) }
        #
        #       it { is_expected.to be_tall }
        #     end
        #
        #     describe '#adult?' do
        #       subject(:person) { described_class.new(age: 17) }
        #
        #       it { is_expected.not_to be_adult }
        #     end
        #   end
        #
        # @example a context is as good a home as a describe
        #   # good - the premise belongs to the scenario, and the scenario is a context
        #   RSpec.describe Person do
        #     describe '#adult?' do
        #       context 'when the person is a minor' do
        #         subject(:person) { described_class.new(age:) }
        #
        #         let(:age) { 17 }
        #
        #         it { is_expected.not_to be_adult }
        #       end
        #     end
        #   end
        class TopLevelLet < RuboCop::Cop::RSpec::Base
          include TopLevelDefinition

          MSG = 'Let `:%<name>s` is declared in the top-level example group, where it reaches every ' \
                'example in the file. Declare it in the group whose examples read it.'
          MSG_UNNAMED = 'A let is declared in the top-level example group, where it reaches every ' \
                        'example in the file. Declare it in the group whose examples read it.'

          private

          def message_for(node)
            name = declared_name(node)

            name.nil? ? MSG_UNNAMED : format(MSG, name:)
          end

          def definition?(node) = let?(node) || let_it_be?(node)
        end
      end
    end
  end
end
