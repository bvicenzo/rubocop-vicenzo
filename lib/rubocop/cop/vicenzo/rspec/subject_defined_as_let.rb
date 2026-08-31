# frozen_string_literal: true

require_relative 'mixin/described_method'
require_relative 'mixin/expectation_target'
require_relative 'mixin/premise_tracking'

module RuboCop
  module Cop
    module Vicenzo
      module RSpec
        # A `let` the expectations assert on, in an example group that declares no subject, is the
        # subject wearing another name. Declare it as one.
        #
        # The subject of a specification is what the sentences are about. When every expectation in a
        # group reads `expect(service)`, `service` is that - and calling it a `let` costs the group the
        # one declaration that says so out loud, leaves `is_expected` unavailable, and hides the
        # redefinitions from the cops that watch subjects for a living.
        #
        # This says nothing about what the subject should hold - that is
        # `Vicenzo/RSpec/SubjectIsMethodResult`'s question, and it already knows the conventions the
        # project declared. The two compose without arguing: declare the subject, and if the value it
        # holds is not fit to be the subject either, the sibling cop says so next.
        #
        # `AllowedMethods` exempts a `let` whose value comes from calling one of the listed methods, for
        # the projects where such a definition is deliberately a `let`. It ships empty.
        #
        # @example
        #   # bad - every expectation is about `service`, yet the group declares no subject
        #   describe '.call' do
        #     context 'when the order is unknown' do
        #       let(:service) { described_class.(order_id: 42) }
        #
        #       it { expect(service).to be_failure }
        #     end
        #   end
        #
        #   # good - the subject is declared, and `is_expected` reads the sentence back
        #   describe '.call' do
        #     context 'when the order is unknown' do
        #       subject(:service) { described_class.(order_id: 42) }
        #
        #       it { is_expected.to be_failure }
        #     end
        #   end
        #
        # @example a let the expectations only read through is a premise
        #   # good - the expectation is about the book, not about the author
        #   describe '#author' do
        #     subject(:book) { create(:book, author:) }
        #
        #     let(:author) { create(:author) }
        #
        #     it { expect(book.author).to eq(author) }
        #   end
        class SubjectDefinedAsLet < RuboCop::Cop::RSpec::Base
          include DescribedMethod
          include ExpectationTarget
          include PremiseTracking

          MSG = 'Let `:%<name>s` is what the expectations assert on, so it is the subject. ' \
                'Declare it with `subject(:%<name>s)`.'

          def on_block(node)
            name = subject_in_disguise(node)

            return if name.nil?

            add_offense(node.send_node, message: format(MSG, name:))
          end

          alias on_numblock on_block
          alias on_itblock on_block

          private

          # The name a definition should have been declared under, or `nil` when it is a `let` like any
          # other: not a definition at all, one the group already has a subject for, one whose value the
          # project exempted, or one no expectation is about.
          def subject_in_disguise(node)
            return unless candidate?(node)

            group = enclosing_example_group(node)

            return if group.nil?

            name = premise_name(node)&.to_sym

            # Two definitions asserted side by side cannot both be this group's subject: they are
            # hidden contexts, which `Vicenzo/RSpec/CompetingSubjects` reads.
            return unless asserted_definitions(group) == [name]

            name
          end

          def candidate?(node)
            (let?(node) || let_it_be?(node)) && !subject_declared?(node) && !allowed_value?(node)
          end

          def allowed_value?(node)
            return false if allowed_methods.empty?

            !call_in_chain(node.body) { |call| allowed_methods.include?(call.method_name.to_s) }.nil?
          end
        end
      end
    end
  end
end
