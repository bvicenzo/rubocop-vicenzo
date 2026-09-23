# frozen_string_literal: true

module RuboCop
  module Cop
    module Vicenzo
      module RSpec
        # A describe nested in a context names a behaviour after the scenario was already set. Describe the
        # behaviour first, and put the scenario inside it.
        #
        # The tree answers three questions, in this order: `describe` - what is being described;
        # `context` - under which circumstances; `it` - with which outcome. A context only means something
        # as a scenario of a behaviour, so a describe below it turns the question upside down.
        #
        # It usually comes from wanting to write a scenario once for two behaviours. Repeat the context
        # under each describe that needs it instead: each behaviour then reads on its own. Do not reach for
        # a `shared_context` to avoid the repetition - it becomes a single place every caller leans on,
        # conditionals creep in to serve each of them, and years later nobody knows why they are there.
        #
        # When the describe states a circumstance rather than a behaviour, it is a context written with the
        # wrong keyword.
        #
        # @example
        #   # bad - the scenario is set before the behaviours it belongs to
        #   RSpec.describe Person do
        #     context 'when the person is a minor' do
        #       subject(:person) { described_class.new(age: 17) }
        #
        #       describe '#adult?' do
        #         it { is_expected.not_to be_adult }
        #       end
        #
        #       describe '#voter?' do
        #         it { is_expected.not_to be_voter }
        #       end
        #     end
        #   end
        #
        #   # good - each behaviour carries its own scenario
        #   RSpec.describe Person do
        #     describe '#adult?' do
        #       context 'when the person is a minor' do
        #         subject(:person) { described_class.new(age: 17) }
        #
        #         it { is_expected.not_to be_adult }
        #       end
        #     end
        #
        #     describe '#voter?' do
        #       context 'when the person is a minor' do
        #         subject(:person) { described_class.new(age: 17) }
        #
        #         it { is_expected.not_to be_voter }
        #       end
        #     end
        #   end
        class DescribeInsideContext < RuboCop::Cop::RSpec::Base
          MSG = 'Do not describe inside a context: a context is a scenario of the behaviour a describe names. ' \
                'Describe the behaviour first and repeat the context under each describe that needs it. ' \
                'If this block states a circumstance, it is a context.'

          # Only the groups that name a behaviour. Aliases a project adds to the RSpec language, such as
          # rswag's `response`, are left out: they do not describe anything.
          DESCRIBES = %i[describe fdescribe xdescribe feature ffeature xfeature example_group].freeze
          CONTEXTS = %i[context fcontext xcontext].freeze

          # @!method describe_definition?(node)
          def_node_matcher :describe_definition?, <<~PATTERN
            (any_block (send #rspec? {#{DESCRIBES.map(&:inspect).join(' ')}} ...) ...)
          PATTERN

          # @!method context_definition?(node)
          def_node_matcher :context_definition?, <<~PATTERN
            (any_block (send nil? {#{CONTEXTS.map(&:inspect).join(' ')}} ...) ...)
          PATTERN

          def on_block(node)
            add_offense(node.send_node) if describe_definition?(node) && inside_a_context?(node)
          end

          alias on_numblock on_block

          private

          # A shared group's scenario lives where it is included, so it cannot be judged here.
          def inside_a_context?(node)
            parent = node.each_ancestor(:any_block).find { |ancestor| spec_group?(ancestor) }

            parent && context_definition?(parent)
          end
        end
      end
    end
  end
end
