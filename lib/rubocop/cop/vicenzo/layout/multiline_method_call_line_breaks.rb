# frozen_string_literal: true

module RuboCop
  module Cop
    module Vicenzo
      module Layout
        # Enforces that method calls in a multiline chain are each on their own line.
        #
        # If a method chain spans more than one line, this cop ensures that every
        # call in the chain is placed on a new line. It prevents "mixed" styles
        # where some methods are on the same line as the receiver while others are broken.
        #
        # @example
        #   # bad
        #   object.method_one
        #     .method_two
        #
        #   # bad
        #   object
        #     .method_one.method_two
        #     .method_three
        #
        #   # good - single line chain
        #   object.method_one.method_two
        #
        #   # good - multiline chain
        #   object
        #     .method_one
        #     .method_two
        #
        #   # good - arguments causing the break (if configured implicitly)
        #   object.method_one(
        #     arg1,
        #     arg2
        #   ).method_two
        #
        # ## Configuration
        #
        # This cop allows you to customize the indentation width used during auto-correction.
        # The default width is 2 spaces relative to the previous line.
        #
        # ```yaml
        # CustomCops/MultilineMethodCallLineBreaks:
        #   IndentationWidth: 4 # (default is 2)
        # ```
        #
        class MultilineMethodCallLineBreaks < Base
          extend RuboCop::Cop::AutoCorrector

          MSG = 'Method calls in a multiline chain must each be on their own line.'
          DEFAULT_INDENTATION_WIDTH = 2
          LEADING_SPACES_PATTERN = /\A */

          OPERATOR_METHODS = %i[[] []= + - * / % ** << >>].freeze

          def on_send(node)
            check_node(node)
          end
          alias on_csend on_send

          private

          def check_node(node)
            return if part_of_larger_chain?(node)
            return if single_line_chain?(node)

            check_chain_structure(node)
          end

          def check_chain_structure(node)
            current = node

            while current.call_type?
              receiver = current.receiver
              break unless receiver

              check_violation(current, receiver)
              current = receiver
            end
          end

          def check_violation(node, receiver)
            return unless same_line?(receiver, node)

            # Se for exceção válida (argumentos, parenteses OU OPERADOR), ignora.
            return if valid_same_line_exception?(node, receiver)

            add_offense(offense_range(node)) do |corrector|
              break_line_before_dot(corrector, node, receiver)
            end
          end

          def valid_same_line_exception?(node, receiver)
            arguments_cause_multiline?(node) || operator_method?(node)
          end

          def operator_method?(node)
            OPERATOR_METHODS.include?(node.method_name)
          end

          def part_of_larger_chain?(node)
            parent = node.parent
            parent&.call_type? && parent.receiver == node
          end

          def single_line_chain?(node)
            root = root_node(node)
            root.loc.last_line == node.loc.last_line
          end

          def root_node(node)
            current = node
            current = current.receiver while current.respond_to?(:receiver) && current.receiver
            current
          end

          def same_line?(receiver, node)
            receiver.loc.last_line == call_start_line(node)
          end

          def call_start_line(node)
            node.loc.dot ? node.loc.dot.line : node.loc.selector.line
          end

          def arguments_cause_multiline?(node)
            return false if node.arguments.empty?
            return false if node.receiver.loc.last_line != call_start_line(node)

            node.multiline?
          end

          def offense_range(node)
            return node.loc.selector unless node.loc.dot
            return node.loc.dot unless node.loc.selector

            node.loc.dot.join(node.loc.selector)
          end

          def break_line_before_dot(corrector, node, receiver)
            dot = node.loc.dot
            return unless dot

            last_line_index = receiver.loc.last_line - 1
            last_line_source = processed_source.lines[last_line_index]

            current_indentation = last_line_source[LEADING_SPACES_PATTERN].length

            indentation = ' ' * (current_indentation + indentation_width)

            corrector.insert_before(dot, "\n#{indentation}")
          end

          def indentation_width
            cop_config.fetch('IndentationWidth', DEFAULT_INDENTATION_WIDTH)
          end
        end
      end
    end
  end
end
