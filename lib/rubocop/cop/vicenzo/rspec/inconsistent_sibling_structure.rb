# frozen_string_literal: true

module RuboCop
  module Cop
    module Vicenzo
      module RSpec
        # Enforces strict structural consistency in RSpec files.
        #
        # It forbids mixing:
        # 1. Examples (`it`) with Groups (`describe` or `context`)
        # 2. Different types of Groups (`describe` with `context`)
        #
        # @example
        #   # bad (Mixing Describe and Context)
        #   RSpec.describe User do
        #     describe '#admin?' do ... end
        #     context 'when user is logged' do ... end
        #   end
        #
        #   # bad (Mixing Example and Context)
        #   RSpec.describe User do
        #     it { is_expected.to be_valid }
        #     context 'when invalid' do ... end
        #   end
        #
        #   # good
        #   RSpec.describe User do
        #     describe '#admin?' do ... end
        #     describe '#client?' do ... end
        #   end
        #
        class InconsistentSiblingStructure < RuboCop::Cop::RSpec::Base
          MSG = 'Do not mix %<type_a>s with %<type_b>s at the same level.'

          EXAMPLES  = %i[it specify example scenario focus].freeze
          DESCRIBES = %i[describe feature experiment].freeze
          CONTEXTS  = %i[context].freeze

          # @!method example_definition?(node)
          def_node_matcher :example_definition?, <<~PATTERN
            (block (send nil? {#{EXAMPLES.map(&:inspect).join(' ')}} ...) ...)
          PATTERN

          # @!method describe_definition?(node)
          def_node_matcher :describe_definition?, <<~PATTERN
            (block (send nil? {#{DESCRIBES.map(&:inspect).join(' ')}} ...) ...)
          PATTERN

          # @!method context_definition?(node)
          def_node_matcher :context_definition?, <<~PATTERN
            (block (send nil? {#{CONTEXTS.map(&:inspect).join(' ')}} ...) ...)
          PATTERN

          def on_block(node)
            return unless example_group?(node)
            return unless node.body

            # Normaliza e classifica em passos separados
            children = child_nodes_for(node)
            found_nodes = classify_children(children)

            validate_consistency(found_nodes)
          end

          alias on_numblock on_block

          private

          def child_nodes_for(node)
            node.body.begin_type? ? node.body.each_child_node : [node.body]
          end

          def classify_children(nodes)
            classified = { example: [], describe: [], context: [] }

            nodes.each do |child|
              next unless child.block_type?

              type = node_type(child)
              classified[type] << child if type
            end

            classified
          end

          def node_type(node)
            if example_definition?(node)
              :example
            elsif describe_definition?(node)
              :describe
            elsif context_definition?(node)
              :context
            end
          end

          def validate_consistency(nodes)
            present_types = nodes.keys.select { |type| nodes[type].any? }

            return if present_types.size <= 1

            check_pair(nodes, :example, :describe)
            check_pair(nodes, :example, :context)
            check_pair(nodes, :describe, :context)
          end

          def check_pair(nodes, type_a, type_b)
            return unless nodes[type_a].any? && nodes[type_b].any?

            nodes[type_b].each do |node|
              add_offense(node, message: format(MSG, type_a: type_a, type_b: type_b))
            end
          end
        end
      end
    end
  end
end
