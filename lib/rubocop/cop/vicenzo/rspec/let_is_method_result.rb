# frozen_string_literal: true

require_relative 'mixin/described_method'
require_relative 'mixin/premise_tracking'
require_relative 'mixin/subject_reference'

module RuboCop
  module Cop
    module Vicenzo
      module RSpec
        # A `let` under an example group that describes a method must not hold what calling that method
        # on the subject returned.
        #
        # This is the same inversion `Vicenzo/RSpec/SubjectIsMethodResult` reports, moved one definition
        # away: the subject stays the object under test, and the result is parked in a `let` that the
        # expectation then asserts on. What the example says out loud becomes a name, and the action -
        # the subject receiving the method - is nowhere in the example that is supposed to describe it.
        #
        # The fix is not to rename the `let` or to move it: it is to undo it. Even when the `let` is read
        # inside an `expect`, what it holds belongs in the expectation itself, where the sentence reads
        # whole - the cat catches the ball, and that is what is asserted.
        #
        # Only calls on the subject count, which is what separates the result from the setup: a `let`
        # calling the described method on some other object is building a premise, not the outcome the
        # example is about. A `let` that only renames the subject is `Vicenzo/RSpec/LetAliasingSubject`'s
        # to report; once it is gone, the call goes through the subject's own name and is reported here.
        # `AllowedMethods` is shared with the sibling cop and ships empty, for the layers whose convention
        # is a single entry point.
        #
        # @example
        #   # bad - the expectation asserts on a name; the cat never catches anything in the example
        #   describe '#catch' do
        #     subject(:cat) { Cat.new(name: 'Bixano') }
        #
        #     let(:catch) { cat.catch(object: Ball.new) }
        #
        #     it { expect(catch).to eq(:success) }
        #   end
        #
        #   # good - the action is in the expectation
        #   describe '#catch' do
        #     subject(:cat) { Cat.new(name: 'Bixano') }
        #
        #     it { expect(cat.catch(object: Ball.new)).to eq(:success) }
        #   end
        #
        # @example a call on another object is a premise, not the result
        #   # good - the described method builds the state the example starts from
        #   describe '#catch' do
        #     subject(:cat) { Cat.new(name: 'Bixano') }
        #
        #     let(:taken_ball) { other_cat.catch(object: Ball.new) }
        #   end
        class LetIsMethodResult < RuboCop::Cop::RSpec::Base
          include DescribedMethod
          include PremiseTracking
          include SubjectReference

          MSG = 'Let `:%<name>s` holds what `%<method>s` returned. Undo it and call `%<method>s` on the ' \
                'subject inside the expectation.'

          def on_block(node)
            return unless let?(node) || let_it_be?(node)

            method_name = described_method_name(node)
            return if method_name.nil? || allowed_methods.include?(method_name)

            invocation = invocation_on_subject(node, method_name)
            return unless invocation

            add_offense(invocation, message: format(MSG, name: premise_name(node), method: method_name))
          end

          alias on_numblock on_block
          alias on_itblock on_block

          private

          # The receiver is read from the chain itself, the call right after the invocation, so that a subject
          # passed along through a local variable or parentheses is still the subject.
          def invocation_on_subject(node, method_name)
            names = subject_names(node)

            call, = ReturnedChain.new(node.body).each_cons(2).find do |invocation, receiver|
              invocation.method?(method_name) && subject_reference?(receiver, names)
            end

            call
          end
        end
      end
    end
  end
end
