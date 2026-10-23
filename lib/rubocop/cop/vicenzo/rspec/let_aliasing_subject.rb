# frozen_string_literal: true

require_relative 'returned_chain'
require_relative 'mixin/premise_tracking'
require_relative 'mixin/subject_reference'

module RuboCop
  module Cop
    module Vicenzo
      module RSpec
        # A `let` whose value is the subject itself is the subject under another name. Refer to the subject by
        # its own name instead.
        #
        # The subject is who the sentences are about. A second name for it splits that across two
        # declarations: the examples reading `hunter` no longer say they are about the subject, and every cop
        # that recognises the subject by its name stops recognising it there. In "the cat caught the ball",
        # calling the cat `hunter` in half of the sentences does not add a character - it hides one.
        #
        # A subject that was declared without a name and is then given one by a `let` is the same thing the
        # other way round: the name belongs to the subject's declaration, `subject(:hunter) { ... }`. Inside a
        # shared group that declares no named subject, the declaration lives where the group is included, so
        # the subject is referred to as `subject`.
        #
        # This composes with `Vicenzo/RSpec/LetIsMethodResult`: once the alias is gone, a `let` that called
        # the described method through it calls it on the subject, and that cop reports it.
        #
        # Only a value that is the subject and nothing more counts. A `let` deriving something from the
        # subject, such as `cat.name`, is a premise, not an alias.
        #
        # @example
        #   # bad - `hunter` is the cat
        #   describe '#catch' do
        #     subject(:cat) { Cat.new(name: 'Bixano') }
        #
        #     let(:hunter) { cat }
        #
        #     it { expect(hunter.catch(object: Ball.new)).to eq(:success) }
        #   end
        #
        #   # good - one name for the subject
        #   describe '#catch' do
        #     subject(:cat) { Cat.new(name: 'Bixano') }
        #
        #     it { expect(cat.catch(object: Ball.new)).to eq(:success) }
        #   end
        #
        # @example an anonymous subject named by a let
        #   # bad - the name belongs to the subject's declaration
        #   describe '#catch' do
        #     subject { Cat.new(name: 'Bixano') }
        #
        #     let(:hunter) { subject }
        #   end
        #
        #   # good
        #   describe '#catch' do
        #     subject(:hunter) { Cat.new(name: 'Bixano') }
        #   end
        #
        # @example a shared group naming the subject of whoever includes it
        #   # bad - the subject is declared where the group is included, under a name it cannot know
        #   shared_examples 'a hunter' do
        #     let(:hunter) { subject }
        #
        #     it { expect(hunter.catch(object: Ball.new)).to eq(:success) }
        #   end
        #
        #   # good - `subject` holds wherever the group is included
        #   shared_examples 'a hunter' do
        #     it { expect(subject.catch(object: Ball.new)).to eq(:success) }
        #   end
        class LetAliasingSubject < RuboCop::Cop::RSpec::Base
          include PremiseTracking
          include SubjectReference

          MSG = 'Let `:%<name>s` is the subject under another name. Refer to the subject as `%<subject>s`.'
          UNNAMED_MSG = 'Let `:%<name>s` is the subject under another name. Name the subject `%<name>s` instead.'

          def on_block(node)
            return unless let?(node)

            reference = sole_call(node.body)
            return unless reference

            names = subject_names(node)
            return unless subject_reference?(reference, names)

            add_offense(node.send_node, message: message(node, reference.method_name, names))
          end

          alias on_numblock on_block
          alias on_itblock on_block

          private

          def sole_call(body)
            calls = ReturnedChain.new(body).to_a

            calls.first if calls.one?
          end

          # `subject` points at the nearest named subject when there is one; without it, the alias is the name
          # the subject was missing. Inside a shared group the subject is declared where the group is included,
          # under a name this group cannot know, so `subject` is the one name that holds everywhere.
          def message(node, reference_name, names)
            name = premise_name(node)
            subject = reference_name == :subject ? names.find { |candidate| candidate != :subject } : reference_name
            return format(MSG, name:, subject:) if subject
            return format(MSG, name:, subject: :subject) if inside_shared_group?(node)

            format(UNNAMED_MSG, name:)
          end

          def inside_shared_group?(node)
            node.each_ancestor(:any_block).any? { |ancestor| shared_group?(ancestor) }
          end
        end
      end
    end
  end
end
