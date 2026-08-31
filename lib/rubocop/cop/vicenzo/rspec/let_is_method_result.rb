# frozen_string_literal: true

require_relative 'mixin/described_method'
require_relative 'mixin/premise_tracking'

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
        # example is about. `AllowedMethods` is shared with the sibling cop and ships empty, for the
        # layers whose convention is a single entry point.
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

          def invocation_on_subject(node, method_name)
            names = subject_names(node)

            call_in_chain(node.body) do |call|
              call.method?(method_name) && subject_reference?(call.receiver, names)
            end
          end

          # `subject` always refers to the subject, declared or implicit; a named one answers to its name
          # as well.
          def subject_names(node)
            names = Set[:subject]

            node.each_ancestor(:any_block).each do |ancestor|
              next unless example_group?(ancestor)

              each_child_block(ancestor) { |child| names << subject_name(child) if subject?(child) }
            end

            names
          end

          # An anonymous `subject!` is still read as `subject`.
          def subject_name(node)
            name = premise_name(node).to_sym

            name == :subject! ? :subject : name
          end

          def subject_reference?(receiver, names)
            return false unless receiver&.send_type? && receiver.receiver.nil? && receiver.arguments.empty?

            names.include?(receiver.method_name)
          end
        end
      end
    end
  end
end
