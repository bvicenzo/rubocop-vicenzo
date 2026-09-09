# frozen_string_literal: true

require_relative 'premise_tracking'

module RuboCop
  module Cop
    module Vicenzo
      module RSpec
        # Shared machinery for the cops that read what a spec declares straight inside the top-level
        # example group - the widest scope a file has, and the one every example written later inherits
        # whether it wanted to or not.
        #
        # The including cop says which children it reads, through `#definition?`, and how to word the
        # offense, through `MSG`. A cop that names what it found overrides `#message_for`, and may read
        # the name through `#declared_name`.
        #
        # Meant for cops inheriting from `RuboCop::Cop::RSpec::Base`: `example_group?` comes from there.
        module TopLevelDefinition
          include PremiseTracking

          def on_block(node)
            return unless top_level_example_group?(node)

            each_child_block(node) do |child|
              add_offense(child.send_node, message: message_for(child)) if definition?(child)
            end
          end

          alias on_numblock on_block

          private

          def top_level_example_group?(node)
            example_group?(node) && outermost_example_group?(node)
          end

          def message_for(_node)
            self.class::MSG
          end

          # The name the definition was given, or `nil` when there is none to read: an anonymous
          # `subject { ... }`, or a name only known at runtime.
          def declared_name(node)
            argument = node.send_node.first_argument

            argument.value.to_sym if argument&.type?(:sym, :str)
          end
        end
      end
    end
  end
end
