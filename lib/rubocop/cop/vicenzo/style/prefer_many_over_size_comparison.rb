# frozen_string_literal: true

module RuboCop
  module Cop
    module Vicenzo
      module Style
        # Enforces `many?` over comparing `size` or `length` with one.
        #
        # Active Support's `Enumerable#many?` exists precisely to name the
        # "more than one element" question that `size > 1` only spells out.
        # RuboCop's own `Style/CollectionQuerying` already covers `count > 1`, but
        # leaves `size` and `length` alone, which is the form most often written.
        # This cop closes that gap.
        #
        # Only an explicit receiver calling `size` or `length` without arguments is
        # flagged, compared with one through `>` or with two through `>=`, on
        # either side of the operator. Like `Style/CollectionQuerying`, the cop
        # only runs when `AllCops: ActiveSupportExtensionsEnabled` is on, since
        # `many?` comes from Active Support. `rubocop-rails` turns it on.
        #
        # @safety
        #   The cop is unsafe because the receiver might not include `Enumerable`.
        #   `String`, for instance, responds to `size` and `length` but not to
        #   `many?`. The same holds for any object with its own `count`, which is
        #   why `Style/CollectionQuerying` is unsafe as well.
        #
        # @example
        #   # bad
        #   items.size > 1
        #   items.length >= 2
        #   1 < items.size
        #
        #   # good
        #   items.many?
        class PreferManyOverSizeComparison < Base
          extend AutoCorrector

          MSG = 'Use `many?` instead of `%<comparison>s`.'

          RESTRICT_ON_SEND = %i[> >= < <=].freeze

          # @!method size_comparison(node)
          def_node_matcher :size_comparison, <<~PATTERN
            {
              (call $(call !nil? {:size :length}) {:> (int 1) | :>= (int 2)})
              (call {(int 1) :< | (int 2) :<=} $(call !nil? {:size :length}))
            }
          PATTERN

          def on_send(node)
            return unless active_support_extensions_enabled?
            return unless (size_node = size_comparison(node))

            message = format(MSG, comparison: comparison_source(node, size_node))

            add_offense(node, message: message) do |corrector|
              corrector.replace(node, "#{size_node.receiver.source}#{size_node.loc.dot.source}many?")
            end
          end
          alias on_csend on_send

          private

          def comparison_source(node, size_node)
            size_source = size_node.method_name

            if node.receiver.equal?(size_node)
              "#{size_source} #{node.method_name} #{node.first_argument.source}"
            else
              "#{node.receiver.source} #{node.method_name} #{size_source}"
            end
          end
        end
      end
    end
  end
end
