# frozen_string_literal: true

module RuboCop
  module Cop
    module Vicenzo
      module Naming
        # Requires every declaration to carry a name, even when the value it
        # holds is not used.
        #
        # A bare `_` states that a value is being ignored, but erases what that
        # value is. Unused today does not mean unusable tomorrow: when the code
        # grows, nobody reading the signature can tell whether the discarded
        # value is the one the new problem needs.
        #
        # The cop only demands that a name exists — it cannot judge whether a
        # name is a good one. That is the author's call, and the offense message
        # asks for a name taken from the domain (`_previous_owner`) rather than
        # one taken from the shape of the value (`_value`, `_key`, `_item`).
        #
        # Anonymous forwarding parameters (`*`, `**`, `&`, `...`) are ignored:
        # they forward arguments instead of discarding them, and `Style/ArgumentsForwarding`
        # actively pushes code towards that form.
        #
        # @example block parameters
        #   # bad
        #   catalog.each { |_, copies| copies.each(&:reserve) }
        #
        #   # good
        #   catalog.each { |_isbn, copies| copies.each(&:reserve) }
        #
        # @example destructured block parameters
        #   # bad
        #   entries.each { |(_, id)| track(id) }
        #
        #   # good
        #   entries.each { |(_label, id)| track(id) }
        #
        # @example method parameters
        #   # bad
        #   def notify(reader, _)
        #     reader.deliver
        #   end
        #
        #   # good
        #   def notify(reader, _delivery_channel)
        #     reader.deliver
        #   end
        #
        # @example multiple assignment
        #   # bad
        #   title, _ = line.split(';')
        #
        #   # good
        #   title, _author = line.split(';')
        #
        # @example rescued errors
        #   # bad
        #   begin
        #     shelf.reorder
        #   rescue ShelfLocked => _
        #     shelf.skip
        #   end
        #
        #   # good
        #   begin
        #     shelf.reorder
        #   rescue ShelfLocked => _lock_conflict
        #     shelf.skip
        #   end
        #
        # @example anonymous forwarding (ignored)
        #   # good
        #   def notify(*)
        #     channel.deliver(*)
        #   end
        #
        #   # good
        #   def notify(...)
        #     channel.deliver(...)
        #   end
        class AnonymousUnusedName < Base
          MSG = 'Name this %<subject>s: an unused value still means something, and `_` hides what. ' \
                'Name it after what it stands for in the domain (`_previous_owner`), not after its ' \
                'shape (`_value`, `_key`, `_item`) — that tells the next reader nothing.'

          BLOCK_PARAMETER  = 'block parameter'
          METHOD_PARAMETER = 'method parameter'
          DISCARDED_VALUE  = 'discarded value'
          RESCUED_ERROR    = 'rescued error'

          ANONYMOUS_NAME_PATTERN = /\A_+\z/

          NAMED_ARGUMENT_TYPES = %i[arg optarg restarg kwarg kwoptarg kwrestarg blockarg shadowarg].freeze
          DEFAULT_VALUE_ARGUMENT_TYPES = %i[optarg kwoptarg].freeze

          # Numbered (`_1`) and implicit (`it`) block parameters are never
          # declared, so they carry no name to check — both node types answer
          # `arguments` with an empty list.
          def on_block(node)
            check_arguments(node.arguments, BLOCK_PARAMETER)
          end
          alias on_numblock on_block
          alias on_itblock on_block

          def on_def(node)
            check_arguments(node.arguments, METHOD_PARAMETER)
          end
          alias on_defs on_def

          def on_masgn(node)
            node.lhs.assignments.each do |assignment|
              next unless assignment.respond_to?(:lvasgn_type?) && assignment.lvasgn_type?

              register_offense(assignment, DISCARDED_VALUE) if anonymous_name?(assignment.children.first)
            end
          end

          def on_resbody(node)
            error = node.exception_variable
            return if error.nil?

            register_offense(error, RESCUED_ERROR) if anonymous_name?(error.children.first)
          end

          private

          def check_arguments(arguments, subject)
            arguments.each do |argument|
              if argument.mlhs_type?
                check_arguments(argument.children, subject)
              elsif anonymous_argument?(argument)
                register_offense(argument_range(argument), subject)
              end
            end
          end

          # An anonymous forwarding parameter (`*`, `**`, `&`) carries no name
          # child at all, and `...` is a `forward_arg`, outside the listed types.
          # Both fall through as allowed.
          def anonymous_argument?(argument)
            NAMED_ARGUMENT_TYPES.include?(argument.type) && anonymous_name?(argument.children.first)
          end

          # An argument carrying a default value spans the whole expression, so
          # only its name is highlighted; every other form is short enough that
          # showing it whole (`*_`, `**_`, `&_`) tells the reader more.
          def argument_range(argument)
            return argument.loc.name if DEFAULT_VALUE_ARGUMENT_TYPES.include?(argument.type)

            argument.source_range
          end

          def anonymous_name?(name)
            !name.nil? && ANONYMOUS_NAME_PATTERN.match?(name.to_s)
          end

          def register_offense(node, subject)
            add_offense(node, message: format(MSG, subject: subject))
          end
        end
      end
    end
  end
end
