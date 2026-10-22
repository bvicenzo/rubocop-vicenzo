# frozen_string_literal: true

require_relative 'mixin/described_method'

module RuboCop
  module Cop
    module Vicenzo
      module RSpec
        # The subject of an example group that describes a method must be the object under test,
        # not what the method returned.
        #
        # A specification is read as a sentence. In "the cat caught the ball", the subject is the
        # cat, not the ball. Storing the return value in the subject inverts that: the object the
        # example is about disappears from the text, the subject's name starts to lie (a
        # `subject(:cat)` holding a `Symbol`), and every scenario that would need the same object
        # in a different state has to redefine the whole call.
        #
        # An example group names a method when its description reads `#instance_method`,
        # `.class_method`, or the bare method name. The cop then looks at the subjects declared
        # under it - including the ones nested in a `context` - and reports the ones whose value
        # comes from calling that method.
        #
        # Some layers legitimately specify a single entry point, where the result is the subject
        # (a service object always invoked through `call`, for instance). `AllowedMethods` exists
        # for those and ships empty: the convention belongs to the project that adopts it, not to
        # this gem. Declaring it there - or excluding a whole directory through the standard
        # `Exclude` - keeps the exemption visible and reviewable in `.rubocop.yml`. The exemption
        # covers the result itself, not what is derived from it: a subject that chains anything
        # after the allowed call - a projection such as `map`, or unwrapping a monad through
        # `value` - is still reported, since it drops the data the examples end up calling the
        # method again to reach.
        #
        # An inline disable directive is not that: it is an exemption nobody reviewed. Dropping
        # the `#` from the description is not either - the cop reads bare descriptions too, and the
        # only thing lost is the reader's clue that a method is being specified there.
        #
        # @example
        #   # bad - the subject is the ball
        #   describe '#catch' do
        #     subject(:catch) { Cat.new(name: 'Bixano').catch(object: Ball.new) }
        #
        #     it { is_expected.to eq(:success) }
        #   end
        #
        #   # good - the subject is the cat
        #   describe '#catch' do
        #     subject(:cat) { Cat.new(name: 'Bixano') }
        #
        #     it { expect(cat.catch(object: Ball.new)).to eq(:success) }
        #   end
        #
        # @example a description without a prefix names a method too
        #   # bad - dropping the '#' silences nothing and costs the reader the
        #   # one clue that a method is being specified here
        #   describe 'catch' do
        #     subject(:catch) { Cat.new(name: 'Bixano').catch(object: Ball.new) }
        #   end
        #
        # @example AllowedMethods: ['call']
        #   # good - a layer whose convention is a single entry point. Declared in
        #   # .rubocop.yml, the exemption stays visible and reviewable, which an
        #   # inline disable directive never is
        #   describe '.call' do
        #     subject(:result) { described_class.(object: Ball.new) }
        #   end
        #
        #   # bad - the subject is derived from the result, not the result itself
        #   describe '.call' do
        #     subject(:ids) { described_class.().map(&:id) }
        #   end
        #
        #   # bad - unwrapping the monad keeps only a part of the result
        #   describe '.call' do
        #     subject(:value) { described_class.(object: Ball.new).value }
        #   end
        class SubjectIsMethodResult < RuboCop::Cop::RSpec::Base
          include DescribedMethod

          MSG = 'Subject holds what `%<method>s` returned, not the object under test. ' \
                'Make the subject the object that receives `%<method>s`, and call it inside the example.'
          DERIVED_MSG = 'Subject derives from what `%<method>s` returned. ' \
                        'Keep the subject as the result of `%<method>s`, and derive from it inside the example.'

          def on_block(node)
            return unless subject?(node)

            method_name = described_method_name(node)
            return if method_name.nil?

            chain = ReturnedChain.new(node.body)
            invocations = chain.select { |call| call.method?(method_name) }
            return if invocations.empty?

            if allowed_methods.include?(method_name)
              check_derivation(chain, invocations.last, method_name)
            else
              add_offense(invocations.first, message: format(MSG, method: method_name))
            end
          end

          alias on_numblock on_block
          alias on_itblock on_block

          private

          # An allowed method may be the subject only as the returned expression itself: its innermost
          # invocation has to be the outermost call of the chain. A block handed to it still belongs to the
          # call; anything chained after it - calling the result again included - does not.
          def check_derivation(chain, innermost_invocation, method_name)
            return if chain.first.equal?(innermost_invocation)

            add_offense(chain.expression, message: format(DERIVED_MSG, method: method_name))
          end
        end
      end
    end
  end
end
