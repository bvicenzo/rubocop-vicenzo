# frozen_string_literal: true

require_relative 'mixin/described_method'
require_relative 'mixin/expectation_target'
require_relative 'mixin/premise_tracking'

module RuboCop
  module Cop
    module Vicenzo
      module RSpec
        # Two or more definitions the expectations assert on, in a group that declares no subject, are
        # contexts that were never written.
        #
        # A group speaks about one subject. When its examples each assert on a different definition, the
        # group is not one scenario with several facts: it is several scenarios sharing a roof, and the
        # circumstance that tells them apart - the one a `context` would have named - lives only in the
        # definitions' names and in the reader's head.
        #
        # The fix is structural, and it is never to pick one of them to promote. Which shape it takes
        # depends on what the definitions are to this group, and working that out is the whole job -
        # which is why the offense names what was found rather than prescribing a repair:
        #
        # 1. They are different scenarios. Give each its own `context`, saying out loud the circumstance
        #    it stands for, and let each declare the subject it is about. What was encoded in
        #    `record_1` / `record_2` becomes a sentence, and the example shrinks to the outcome alone.
        # 2. One outcome covers them all. Then they were never subjects: they are the premise. Move them
        #    into a `before`, unnamed, and assert on the collection they belong to.
        #
        # Both are corrections to the spec. Neither is silencing the cop: a definition named
        # `record_1` is the shape this smell takes, so renaming it settles nothing, and an inline
        # disable directive keeps the hidden scenario hidden - which is the cost being paid here.
        #
        # A group that already declares a subject is left alone - there the subject is settled and the
        # other definitions are premises, whatever their names suggest.
        #
        # @example
        #   # bad - two subjects under one roof; the circumstances are only in the names
        #   describe '#approved?' do
        #     let!(:reviewed_post) { create(:post, reviewed_at: Time.current) }
        #     let!(:draft_post) { create(:post) }
        #
        #     it { expect(reviewed_post).to be_approved }
        #     it { expect(draft_post).not_to be_approved }
        #   end
        #
        #   # good - one context per scenario, each with its own subject
        #   describe '#approved?' do
        #     context 'when the post has been reviewed' do
        #       subject(:post) { create(:post, reviewed_at: Time.current) }
        #
        #       it { is_expected.to be_approved }
        #     end
        #
        #     context 'without a review' do
        #       subject(:post) { create(:post) }
        #
        #       it { is_expected.not_to be_approved }
        #     end
        #   end
        #
        # @example when one outcome covers every record, they are the premise
        #   # bad - two records named as if each were a subject
        #   describe '#deactivate' do
        #     let!(:pending_alert) { create(:alert, :pending) }
        #     let!(:firing_alert) { create(:alert, :firing) }
        #
        #     it 'dismisses every alert', :aggregate_failures do
        #       monitor.deactivate
        #
        #       expect(pending_alert.reload).to be_dismissed
        #       expect(firing_alert.reload).to be_dismissed
        #     end
        #   end
        #
        #   # good - the records are the premise, and the outcome is about the collection
        #   describe '#deactivate' do
        #     before do
        #       create(:alert, :pending)
        #       create(:alert, :firing)
        #     end
        #
        #     it 'dismisses every alert' do
        #       monitor.deactivate
        #
        #       expect(monitor.alerts).to contain_exactly(be_dismissed, be_dismissed)
        #     end
        #   end
        #
        # @example records a single expectation compares are not competing subjects
        #   # good - both records build the one answer the example is about
        #   describe '.recent' do
        #     let!(:recent_order) { create(:order, created_at: 1.day.ago) }
        #     let!(:old_order) { create(:order, created_at: 1.year.ago) }
        #
        #     it { expect(described_class.recent).to contain_exactly(recent_order) }
        #   end
        class CompetingSubjects < RuboCop::Cop::RSpec::Base
          include DescribedMethod
          include ExpectationTarget
          include PremiseTracking

          MSG = 'The expectations here are about %<names>s, so this group has no one subject. Work out ' \
                'what these definitions are to it, and let the structure say so.'

          def on_block(node)
            return unless example_group?(node)

            names = competing_names(node)

            return if names.size < 2

            add_offense(node.send_node, message: format(MSG, names: names.join(', ')))
          end

          alias on_numblock on_block
          alias on_itblock on_block

          private

          def competing_names(group)
            return [] if declares_subject?(group)

            asserted_definitions(group).reject { |name| exempt?(group, name) }.map { |name| "`:#{name}`" }
          end

          def exempt?(group, name)
            return false if allowed_methods.empty?

            definition = definition_named(group, name)

            !definition.nil? && !call_in_chain(definition.body) do |call|
              allowed_methods.include?(call.method_name.to_s)
            end.nil?
          end

          def definition_named(group, name)
            found = nil

            each_child_block(group) do |child|
              found ||= child if premise?(child) && premise_name(child)&.to_sym == name
            end

            found
          end
        end
      end
    end
  end
end
