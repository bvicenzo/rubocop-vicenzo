# frozen_string_literal: true

module RuboCop
  module Cop
    module Vicenzo
      module Style
        # Enforces passing `symbolize_names: true` to `JSON.parse` so the
        # resulting hash uses symbol keys instead of strings.
        #
        # An explicit `symbolize_names: false` is treated as a deliberate
        # opt-out and is allowed. Calls whose options cannot be analyzed
        # statically (a variable, splat, or double splat) are ignored to
        # avoid false positives.
        #
        # @example
        #   # bad
        #   JSON.parse(payload)
        #
        #   # bad
        #   JSON.parse(payload, max_nesting: 5)
        #
        #   # good
        #   JSON.parse(payload, symbolize_names: true)
        #
        #   # good (deliberate opt-out)
        #   JSON.parse(payload, symbolize_names: false)
        class JsonParseSymbolizeNames < Base
          MSG = 'Pass `symbolize_names: true` to `JSON.parse` so keys are symbols. ' \
                'Only when string keys are truly required, set `symbolize_names: false` explicitly.'

          RESTRICT_ON_SEND = [:parse].freeze

          # @!method json_parse?(node)
          def_node_matcher :json_parse?, <<~PATTERN
            (send (const {nil? cbase} :JSON) :parse ...)
          PATTERN

          def on_send(node)
            return unless json_parse?(node)

            add_offense(node) if missing_symbolize_names?(node)
          end
          alias on_csend on_send

          private

          def missing_symbolize_names?(node)
            return false if node.arguments.any?(&:splat_type?)

            options = options_hash(node)
            return node.arguments.one? if options.nil?
            return false if options.children.any?(&:kwsplat_type?)

            !symbolize_names?(options)
          end

          # The options hash is the last argument when it is a hash literal
          # (covers both `{ ... }` and trailing keyword arguments). A non-hash
          # last argument (e.g. a variable) means we cannot inspect it.
          def options_hash(node)
            last_argument = node.last_argument
            return unless last_argument&.hash_type?

            last_argument
          end

          def symbolize_names?(options)
            options.each_pair.any? { |pair| pair.key.sym_type? && pair.key.value == :symbolize_names }
          end
        end
      end
    end
  end
end
