# frozen_string_literal: true

require 'rubocop'

module RuboCop
  module Cop
    module Vicenzo
      module RSpec
        # Checks for methods, classes, or modules defined directly within
        # RSpec blocks or at the top level of a spec file.
        #
        # Such definitions pollute the global namespace or the test class scope,
        # leading to state leaking and intermittent test failures.
        #
        # @example
        #   # bad
        #   describe User do
        #     def setup_user
        #       # ...
        #     end
        #   end
        #
        #   # bad
        #   def global_helper
        #   end
        #
        #   # bad
        #   def stub_service
        #     allow(Service).to receive(:call)
        #   end
        #
        #   # good
        #   describe User do
        #     let(:user) { create(:user) }
        #   end
        #
        #   # good (inside anonymous class)
        #   let(:model) do
        #     Class.new do
        #       def safe_method; end
        #     end
        #   end
        #
        #   # good
        #   before do
        #     allow(Service).to receive(:call)
        #   end
        #
        class LeakyDefinition < RuboCop::Cop::RSpec::Base
          MSG = 'Do not define methods, classes, or modules directly in the global scope or within spec blocks. ' \
                'This pollutes the namespace. ' \
                'Move this logic to `spec/support`, use `let`, before, ' \
                'or encapsulate it within a safe structure (e.g., `Class.new`).'

          # Matcher to identify dynamic class/module definitions commonly used in specs
          # Looks for blocks applied to Class.new, Module.new, or Struct.new
          # @!method dynamic_definition?(node)
          def_node_matcher :dynamic_definition?, <<~PATTERN
              (block
                (send
                  (const {nil? cbase} {:Class :Module :Struct}) :new ...)
                ...
            )
          PATTERN

          def on_def(node)
            check_node(node)
          end

          def on_class(node)
            check_node(node)
          end

          def on_module(node)
            check_node(node)
          end

          private

          def check_node(node)
            # If inside a safe scope (static or dynamic class/module), it's allowed.
            return if inside_safe_scope?(node)

            add_offense(node)
          end

          def inside_safe_scope?(node)
            # Traverse ancestors to find a "protective shield"
            node.each_ancestor.any? do |ancestor|
              # 1. Is it a traditional definition? (class Foo; end)
              next true if ancestor.type?(:class, :module)

              # 2. Is it a dynamic definition? (Class.new do; end)
              next true if dynamic_definition?(ancestor)
            end
          end
        end
      end
    end
  end
end
