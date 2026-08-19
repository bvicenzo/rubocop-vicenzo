# frozen_string_literal: true

module RuboCop
  module Cop
    module Vicenzo
      module RSpec
        # Shared helpers to walk example groups keeping track of the premises
        # (`let`, `let!`, `let_it_be`, `subject`) visible at each level, and to
        # resolve which premise a call chain starts from.
        module PremiseTracking
          extend RuboCop::AST::NodePattern::Macros

          # Brings `Helpers` and `Subjects` into this module's constant lookup, so the patterns below resolve the
          # same RSpec DSL names the cops do.
          include RuboCop::RSpec::Language

          # Hooks that build the state an example starts from. `after` is left
          # out on purpose: mutating there is teardown, not a premise.
          SETUP_HOOKS = %i[before around prepend_before append_before].freeze

          # @!method premise_name(node)
          def_node_matcher :premise_name, <<~PATTERN
            (any_block
              (send nil?
                {
                  {#Helpers.all :let_it_be :let_it_be!} ({str sym} $_)
                  | #Subjects.all (sym $_)
                  | $#Subjects.all
                }
                ...
              )
              ...
            )
          PATTERN

          # @!method root_receiver_name(node)
          #   Name of the local call a chain starts from, e.g. `:order`
          #   for `order.shipment.update!`.
          def_node_matcher :root_receiver_name, <<~PATTERN
            (send nil? $_)
          PATTERN

          private

          def walk_example_group(group, premises)
            each_child_block(group) do |child|
              if example_group?(child)
                walk_example_group(child, premises)
              elsif premise?(child)
                on_premise(child, premises)
              elsif setup_hook?(child)
                on_setup_hook(child, premises)
              end
            end
          end

          # Every premise in the file, not only the ones an ancestor group declares. A premise defined in a child
          # group is still the premise a definition above reads — the "abstract let" shape — and that is the hardest
          # one to follow when reading.
          def all_premises(root)
            names = Set.new

            names << premise_name(root) if premise?(root)
            root.each_descendant(:block, :numblock) { |node| names << premise_name(node) if premise?(node) }

            names
          end

          def each_child_block(group)
            body = group.body

            return if body.nil?

            children = body.begin_type? ? body.children : [body]

            children.each { |child| yield(child) if child.any_block_type? }
          end

          def outermost_example_group?(node)
            node.each_ancestor(:block, :numblock).none? { |ancestor| example_group?(ancestor) }
          end

          def premise?(node) = let?(node) || let_it_be?(node) || subject?(node)

          # @!method let_it_be?(node)
          def_node_matcher :let_it_be?, <<~PATTERN
            (any_block (send nil? {:let_it_be :let_it_be!} ...) ...)
          PATTERN

          def setup_hook?(node) = hook?(node) && SETUP_HOOKS.include?(node.method_name)

          def premise_receiver(node, premises)
            receiver = node.receiver

            while receiver&.send_type?
              name = root_receiver_name(receiver)

              return name if name && premises.include?(name)

              receiver = receiver.receiver
            end

            nil
          end

          def mutating_calls(node)
            body = node.body

            return [] if body.nil?

            body.each_node(:send).to_a
          end
        end
      end
    end
  end
end
