# frozen_string_literal: true

module RuboCop
  module Cop
    module Vicenzo
      module RSpec
        # Do not define the same let in nested example groups.
        #
        # It makes the tests more dificult to read and indicates that exists hidden scenarios (contexts)
        #
        # @example `Hidden context`
        #
        #   # bad
        #
        #   describe '#authorized?' do
        #     subject(:action) { create(:action) }
        #     let(:user) { create(:user, :admin) }
        #
        #     it { expect(action).to be_authorized(user) }
        #
        #     context 'when user is not admin' do
        #       let(:user) { create(:user, :analyst) }
        #
        #       it { expect(action).not_to be_authorized(user) }
        #     end
        #   end
        #
        #   # good
        #
        #   describe '#authorized?' do
        #     subject(:action) { create(:action) }
        #
        #     context 'when user is not admin' do
        #       let(:user) { create(:user, :analyst) }
        #
        #       it { expect(action).not_to be_authorized(user) }
        #     end
        #
        #     context 'when user is admin' do # this context was hidden
        #       let(:user) { create(:user, :admin) }
        #
        #       it { expect(action).to be_authorized(user) }
        #     end
        #   end
        class NestedLetRedefinition < RuboCop::Cop::RSpec::Base
          MSG = 'Let `:%<name>s` is already defined in ancestor(s) block(s) at: %<definitions>s.'

          # @!method let_name(node)
          def_node_matcher :let_name, <<~PATTERN
            {
              (block (send nil? #Helpers.all ({str sym} $_) ...) ...)
              (send nil? #Helpers.all ({str sym} $_) block_pass)
            }
          PATTERN

          def on_block(node)
            check_let_redefinitions(node, {}) if example_group?(node)
          end

          private

          def check_let_redefinitions(node, let_definitions)
            node.body.each_child_node do |child|
              if child.block_type?
                if example_group?(child)
                  check_let_redefinitions(child, let_definitions.dup)
                elsif let?(child)
                  check_let(child, let_definitions)
                end
              end
            end
          end

          def check_let(let_node, let_definitions)
            name = let_name(let_node).to_s.to_sym

            if let_definitions.key?(name)
              add_offense(let_node, message: redefined_let_message(name, let_definitions))
              let_definitions[name] << line_location(let_node)
            else
              let_definitions[name] = [line_location(let_node)]
            end
          end

          def redefined_let_message(name, let_definitions)
            format(MSG, name:, definitions: let_definitions[name].join(', '))
          end

          def line_location(node)
            node.source_range.line
          end
        end
      end
    end
  end
end
