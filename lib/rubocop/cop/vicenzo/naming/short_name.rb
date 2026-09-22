# frozen_string_literal: true

module RuboCop
  module Cop
    module Vicenzo
      module Naming
        # Checks local variable names for how many letters they actually spell.
        #
        # A single letter or a two-letter abbreviation almost never carries the
        # business meaning of the value it holds. `p`, `w`, `v`, `i` say nothing,
        # and `_p` is still a single letter with an underscore in front of it.
        #
        # Underscores do not count towards the length, so `a_b` spells two
        # letters, not three. The cop does not judge which name is a good one —
        # it only measures how much was written down; whether the name belongs to
        # the domain is the author's call, and the message asks for it.
        #
        # Block and method parameters are left to `Naming/BlockParameterName` and
        # `Naming/MethodParameterName`; this gem's `config/style.yml` raises the
        # former to the same minimum. Rescued errors are left to
        # `Naming/RescuedExceptionsVariableName`, and names made only of
        # underscores belong to `Vicenzo/Naming/AnonymousUnusedName`.
        #
        # A short name that exists only to feed a keyword argument shorthand is
        # allowed: the name was imposed by the signature that receives it, not
        # chosen, and it is that signature the parameter cops point at. The fix
        # cascades from there.
        #
        # @example
        #   # bad
        #   v = shelf.capacity
        #
        #   # good
        #   volume = shelf.capacity
        #
        # @example multiple assignment
        #   # bad
        #   x, y = coordinates
        #
        #   # good
        #   column, row = coordinates
        #
        # @example underscores do not count as letters
        #   # bad
        #   a_b = shelf.capacity
        #
        #   # good
        #   available_books = shelf.capacity
        #
        # @example an unused name is still a name
        #   # bad
        #   _p = catalog.first
        #
        #   # good
        #   _publisher = catalog.first
        #
        # @example keyword argument shorthand (allowed)
        #   # good
        #   height = 10
        #   width = 15
        #   area(height:, width:)
        #
        #   # good — `h` and `w` are imposed by the signature of `area`
        #   h = 10
        #   w = 15
        #   area(h:, w:)
        #
        # @example MinNameLength: 5
        #   # bad
        #   book = build
        #
        #   # good
        #   book_title = build
        class ShortName < Base
          MSG = 'Name `%<name>s` spells %<length>d letter(s); at least %<minimum>d are required. ' \
                'A letter or an abbreviation carries no meaning to the next reader — write the ' \
                'whole word, in the language of the domain (`waiting_time`), not a shapeless ' \
                'label (`key`, `value`, `item`).'

          DEFAULT_MIN_NAME_LENGTH = 3

          ANONYMOUS_NAME_PATTERN = /\A_+\z/

          SCOPE_TYPES = %i[def defs block numblock itblock].freeze

          def on_lvasgn(node)
            name = node.children.first
            return if anonymous?(name) || rescued_error?(node) || forwarded_by_shorthand?(node, name)

            length = spelled_length(name)
            return if length >= min_name_length

            add_offense(node.loc.name, message: format(MSG, name: name, length: length, minimum: min_name_length))
          end

          private

          # Underscores separate words, they do not spell any, so they are not
          # counted: `a_b` is two letters long.
          def spelled_length(name)
            name.to_s.delete('_').length
          end

          def anonymous?(name)
            ANONYMOUS_NAME_PATTERN.match?(name.to_s)
          end

          def rescued_error?(node)
            parent = node.parent
            parent&.resbody_type? && parent.exception_variable == node
          end

          # `area(h:)` omits the value, so `h` is the name the receiving signature
          # asks for. Looking within the enclosing scope keeps unrelated calls
          # elsewhere in the file from excusing the name.
          def forwarded_by_shorthand?(node, name)
            enclosing_scope(node)
              .each_node(:pair)
              .any? { |pair| pair.value_omission? && pair.key.value == name }
          end

          def enclosing_scope(node)
            node.each_ancestor(*SCOPE_TYPES).first || processed_source.ast
          end

          def min_name_length
            cop_config.fetch('MinNameLength', DEFAULT_MIN_NAME_LENGTH)
          end
        end
      end
    end
  end
end
