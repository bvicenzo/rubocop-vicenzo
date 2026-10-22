# frozen_string_literal: true

module RuboCop
  module Cop
    module Vicenzo
      module RSpec
        # The calls the value of a block body is built on, outermost first: `Cat.new.catch(ball).to_s` yields `to_s`,
        # `catch` and `new`, while `Cat.new(catches: other.catch)` yields only `new` - nothing of `catch` reaches the
        # value.
        #
        # The walk starts at the statement the body returns and follows its receivers, seeing through what only
        # passes a value along: parentheses, an assignment, and a local variable, which answers to its latest
        # assignment among the statements before the one reading it.
        class ReturnedChain
          include Enumerable

          attr_reader :expression

          def initialize(body)
            @statements = statements_of(body)
            @expression = @statements.last
          end

          def each
            node = expression
            reach = @statements.size - 1

            while node
              node, reach = value_of(node, reach)
              node = node.send_node if node&.any_block_type?
              break unless node&.type?(:call)

              yield node
              node = node.receiver
            end
          end

          private

          def statements_of(body)
            return [] if body.nil?

            body.begin_type? ? body.children : [body]
          end

          # `reach` is the index of the statement the node is read in: a variable only answers to an assignment made
          # before it, which keeps `caught = caught.to_s` from answering to itself.
          def value_of(node, reach)
            loop do
              case node&.type
              when :begin then node = node.children.last
              when :lvasgn then node = node.expression
              when :lvar
                reach = assignment_before(node.name, reach)
                node = reach && @statements[reach]
              else return [node, reach]
              end
            end
          end

          def assignment_before(name, reach)
            (reach - 1).downto(0).find do |index|
              statement = @statements[index]
              statement.lvasgn_type? && statement.name == name
            end
          end
        end
      end
    end
  end
end
