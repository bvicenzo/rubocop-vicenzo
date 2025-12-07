# frozen_string_literal: true

module RuboCop
  module Cop
    module Vicenzo
      module Layout
        # Checks if a method call spans multiple lines, but the argument list
        # starts on the same line as the method.
        #
        # If a method call is multiline (either due to many arguments or a
        # multiline argument like a Hash/Array), this cop enforces that the
        # call must use parentheses and break the line before the first argument.
        #
        # @example
        #   # bad - simple arguments spanning lines
        #   method_name arg1,
        #               arg2
        #
        #   # bad - multiline hash on the same line
        #   create :user, { name: 'John',
        #                   email: 'john@example.com' }
        #
        #   # bad - multiline array on the same line
        #   process_items [1,
        #                  2], other_arg
        #
        #   # good
        #   method_name(
        #     arg1,
        #     arg2
        #   )
        #
        #   # good
        #   create(
        #     :user,
        #     {
        #       name: 'John',
        #       email: 'john@example.com'
        #     }
        #   )
        #
        #   # good
        #   process_items(
        #     [
        #       1,
        #       2
        #     ],
        #     other_arg
        #   )
        #
        class WrapMultilineArguments < Base
          extend RuboCop::Cop::AutoCorrector
          include RuboCop::Cop::RangeHelp

          MSG = 'Method call with multiline arguments must use parentheses and break line before the first argument.'

          def on_send(node)
            check_node(node)
          end
          alias on_csend on_send

          private

          def check_node(node)
            return unless node.arguments?
            return unless node.multiline?

            return if node.setter_method? || (node.parenthesized? && node.first_argument.loc.line > call_line(node))

            add_offense(node) do |corrector|
              autocorrect(corrector, node)
            end
          end

          def call_line(node)
            node.loc.selector ? node.loc.selector.line : node.loc.line
          end

          def autocorrect(corrector, node)
            ensure_parentheses(corrector, node)
            break_line_before_first_arg(corrector, node)
          end

          def ensure_parentheses(corrector, node)
            return if node.parenthesized?

            if node.loc.selector
              gap = range_between(node.loc.selector.end_pos, node.first_argument.source_range.begin_pos)
              corrector.replace(gap, '(')
            else
              corrector.insert_before(node.first_argument, '(')
            end

            corrector.insert_after(node.last_argument, ')')
          end

          def break_line_before_first_arg(corrector, node)
            indentation = ' ' * (node.loc.column + indentation_width)
            corrector.insert_before(node.first_argument, "\n#{indentation}")
          end

          def indentation_width
            cop_config.fetch('IndentationWidth', 2)
          end
        end
      end
    end
  end
end
