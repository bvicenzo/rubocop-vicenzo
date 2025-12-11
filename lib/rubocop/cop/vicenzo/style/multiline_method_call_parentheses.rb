# frozen_string_literal: true

module RuboCop
  module Cop
    module Vicenzo
      module Style
        # Enforces parentheses for method calls with arguments that span multiple lines.
        # Single-line calls are ignored (parentheses are optional).
        #
        # This cop accepts an `AllowedMethods` configuration to exempt specific methods
        # from this rule. This is particularly useful for Fluent DSLs (like RSpec's
        # `to`, `change`, etc.) where parentheses might hurt readability or conflict
        # with layout rules.
        #
        # @example
        #   # bad
        #   method_name arg1,
        #               arg2
        #
        #   # good
        #   method_name(arg1,
        #               arg2)
        #
        #   # good (single line is always allowed)
        #   method_name arg1, arg2
        #
        # @example AllowedMethods: ['to']
        #   # good (allowed by configuration)
        #   expect { action }.to change {
        #     model.attribute
        #   }
        #
        class MultilineMethodCallParentheses < Base
          extend RuboCop::Cop::AutoCorrector
          include RuboCop::Cop::RangeHelp

          MSG = 'Use parentheses for method calls with arguments that span multiple lines.'

          def on_send(node)
            check_node(node)
          end
          alias on_csend on_send

          private

          def check_node(node)
            return unless node.arguments?
            return unless node.multiline?
            return if node.parenthesized? || node.operator_method? || node.setter_method? || allowed_method?(node)

            add_offense(node) do |corrector|
              autocorrect(corrector, node)
            end
          end

          def allowed_method?(node)
            allowed_methods.include?(node.method_name.to_s)
          end

          def allowed_methods
            cop_config.fetch('AllowedMethods', [])
          end

          def autocorrect(corrector, node)
            if node.loc.selector
              gap_range = range_between(node.loc.selector.end_pos, node.first_argument.source_range.begin_pos)
              corrector.replace(gap_range, '(')
            else
              corrector.insert_before(node.first_argument, '(')
            end

            corrector.insert_after(node.last_argument, ')')
          end
        end
      end
    end
  end
end
