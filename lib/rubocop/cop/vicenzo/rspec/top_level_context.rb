# frozen_string_literal: true

require_relative 'mixin/top_level_definition'

module RuboCop
  module Cop
    module Vicenzo
      module RSpec
        # A context declared straight inside the top-level example group is a scenario for the whole
        # file. Nest it in the group whose behaviour it is a scenario of.
        #
        # A context answers "under which circumstances?", and the question only means something once a
        # behaviour has been named. Declared at the root, the scenario applies to every example in the
        # file at once - the same overreach a root subject or a root let has, since the premises the
        # context declares are handed to everything written under it later.
        #
        # It is also how the file loses the describe it never had: the first behaviour goes under
        # `context 'when ...'`, the second one needs the same circumstances worded slightly differently,
        # and what should have been two groups naming two behaviours becomes a tree of scenarios naming
        # none.
        #
        # @example
        #   # bad - the scenario is about `#adult?`, yet it covers the whole file
        #   RSpec.describe Person do
        #     context 'when the person is a minor' do
        #       subject(:person) { described_class.new(age: 17) }
        #
        #       it { is_expected.not_to be_adult }
        #     end
        #   end
        #
        #   # good - the behaviour is named first, the scenario belongs to it
        #   RSpec.describe Person do
        #     describe '#adult?' do
        #       context 'when the person is a minor' do
        #         subject(:person) { described_class.new(age: 17) }
        #
        #         it { is_expected.not_to be_adult }
        #       end
        #     end
        #   end
        class TopLevelContext < RuboCop::Cop::RSpec::Base
          include TopLevelDefinition

          MSG = 'This context is declared in the top-level example group, so it is a scenario for every ' \
                'example in the file. Nest it in the group whose behaviour it is a scenario of.'

          CONTEXTS = %i[context fcontext xcontext].freeze

          # @!method context_definition?(node)
          def_node_matcher :context_definition?, <<~PATTERN
            (any_block (send nil? {#{CONTEXTS.map(&:inspect).join(' ')}} ...) ...)
          PATTERN

          private

          def definition?(node) = context_definition?(node)
        end
      end
    end
  end
end
