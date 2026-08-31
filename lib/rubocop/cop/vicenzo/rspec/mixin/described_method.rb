# frozen_string_literal: true

module RuboCop
  module Cop
    module Vicenzo
      module RSpec
        # Shared helpers for the cops that read an example group naming a method - `#instance_method`,
        # `.class_method`, `#method(signature)`, or the bare method name - and ask what the definitions
        # under it are built from.
        #
        # Meant for cops inheriting from `RuboCop::Cop::RSpec::Base`: `example_group?` and `cop_config`
        # come from there.
        module DescribedMethod
          # `#catch`, `.catch`, and the form carrying a signature such as `#catch(object:)`.
          PREFIXED_METHOD_DESCRIPTION = /\A[#.](?<name>.+?)(?:\(.*\))?\z/
          # `catch` - a description that is nothing but a method name.
          BARE_METHOD_DESCRIPTION = /\A(?<name>\w+[?!=]?)\z/

          private

          # The nearest enclosing example group naming a method: a definition sitting in a `context` still
          # answers to the `describe '#method'` wrapping it.
          def described_method_name(node)
            node
              .each_ancestor(:any_block)
              .lazy
              .filter_map { |ancestor| method_name_from(ancestor) if example_group?(ancestor) }
              .first
          end

          def method_name_from(node)
            description = node.send_node.first_argument
            return unless description.respond_to?(:str_type?) && description.str_type?

            match = PREFIXED_METHOD_DESCRIPTION.match(description.value) ||
                    BARE_METHOD_DESCRIPTION.match(description.value)

            match&.[](:name)
          end

          def allowed_methods
            cop_config.fetch('AllowedMethods', [])
          end

          # Walks the expression a definition returns down its receiver chain, yielding each call, so that
          # `Cat.new.catch(ball).to_s` is seen as built on `catch` while `Cat.new(catches: other.catch)`
          # is not - there, nothing of `catch` reaches the value.
          def call_in_chain(body)
            node = returned_expression(body)

            while node
              node = node.send_node if node.any_block_type?
              break unless node.type?(:call)
              return node if yield(node)

              node = node.receiver
            end

            nil
          end

          def returned_expression(body)
            return if body.nil?

            body.begin_type? ? body.children.last : body
          end
        end
      end
    end
  end
end
