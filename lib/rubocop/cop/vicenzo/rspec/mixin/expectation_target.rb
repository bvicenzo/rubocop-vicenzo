# frozen_string_literal: true

module RuboCop
  module Cop
    module Vicenzo
      module RSpec
        # Shared helpers to tell which definitions an example group's expectations are *about*.
        #
        # Only the left-hand side of an expectation counts - `expect(order)` and `expect { order }`.
        # What sits inside the matcher is the expected answer, not the subject: in
        # `expect(described_class.recent).to contain_exactly(recent_order)`, `recent_order` is part of the
        # answer, and reading it as the subject would turn the correct way of specifying a scope into an
        # offense.
        #
        # Meant for cops inheriting from `RuboCop::Cop::RSpec::Base` and including `PremiseTracking`:
        # `let?`, `example_group?` and `premise_name` come from there.
        module ExpectationTarget
          EXPECTATION_RUNNERS = %i[to not_to to_not].freeze

          # Verifying a message is a statement about a collaborator, never about the subject.
          MESSAGE_MATCHERS = %i[receive have_received receive_messages receive_message_chain].freeze

          private

          # The definitions declared directly in this group that its expectations assert on.
          def asserted_definitions(group)
            names = []

            each_child_block(group) do |child|
              next unless let?(child) || let_it_be?(child)

              name = premise_name(child)&.to_sym

              names << name if name && asserted_on?(group, name)
            end

            names
          end

          def asserted_on?(group, name)
            return false if group.nil?

            group.each_descendant(:send).any? { |send_node| expectation_on?(send_node, name) }
          end

          def expectation_on?(node, name)
            return false unless node.method?(:expect) && node.receiver.nil?
            return false unless reference?(node.first_argument || node.block_node&.body, name)

            !message_expectation?(node)
          end

          def reference?(node, name)
            return false unless node&.send_type? && node.receiver.nil? && node.arguments.empty?

            node.method?(name)
          end

          def message_expectation?(node)
            MESSAGE_MATCHERS.include?(matcher_name(expectation_matcher(node)))
          end

          def expectation_matcher(node)
            runner = node.block_node&.parent || node.parent

            return unless runner&.send_type? && EXPECTATION_RUNNERS.include?(runner.method_name)

            runner.first_argument
          end

          # The matcher a chained expectation starts from: `receive(:set).with(key)` starts at `receive`.
          def matcher_name(node)
            node = node.receiver while node&.receiver

            node&.method_name
          end

          def enclosing_example_group(node)
            node.each_ancestor(:any_block).find { |ancestor| example_group?(ancestor) }
          end

          def subject_declared?(node)
            node.each_ancestor(:any_block).any? do |ancestor|
              next false unless example_group?(ancestor)

              declares_subject?(ancestor)
            end
          end

          def declares_subject?(group)
            declared = false

            each_child_block(group) { |child| declared ||= subject?(child) }

            declared
          end
        end
      end
    end
  end
end
