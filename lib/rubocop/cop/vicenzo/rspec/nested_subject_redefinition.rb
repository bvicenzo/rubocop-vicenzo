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
        #   describe '#can_access?' do
        #     subject(:user) { create(:user, :admin) }
        #
        #     it { expect(user).to can_access(:products) }
        #
        #     context 'when user is not admin' do
        #       subject(:user) { create(:user, :analyst) }
        #
        #       it { expect(user).not_to can_access(:products) }
        #     end
        #   end
        #
        #   # good
        #
        #   describe '#can_access?' do
        #     context 'when user is not admin' do
        #       subject(:user) { create(:user, :analyst) }
        #
        #       it { expect(user).not_to can_access(:products) }
        #     end
        #
        #     context 'when user is admin' do # this context was hidden
        #       subject(:user) { create(:user, :admin) }
        #
        #       it { expect(action).to can_access(:products) }
        #     end
        #   end
        class NestedSubjectRedefinition < RuboCop::Cop::RSpec::Base
          MSG = 'Subject `:%<name>s` is already defined in ancestor(s) block(s) at: %<definitions>s.'

          # @!method subject_name(node)
          #   Find a named or unnamed subject definition
          #
          #   @example anonymous subject
          #     subject_name(parse('subject { foo }').ast) do |name|
          #       name # => :subject
          #     end
          #
          #   @example named subject
          #     subject_name(parse('subject(:thing) { foo }').ast) do |name|
          #       name # => :thing
          #     end
          #
          #   @param node [RuboCop::AST::Node]
          #
          #   @yield [Symbol] subject name
          def_node_matcher :subject_name, <<-PATTERN
            (block
              (send nil?
                { #Subjects.all (sym $_) | $#Subjects.all }
              ) args ...)
          PATTERN

          def on_block(node)
            check_subject_redefinitions(node, {}) if example_group?(node)
          end

          alias on_numblock on_block

          private

          def name_for(subject_node)
            name = subject_name(subject_node)

            name == :subject ? :anonymous : name
          end

          def check_subject_redefinitions(node, subject_definitions)
            node.body.each_child_node do |child|
              if child.block_type?
                if example_group?(child)
                  check_subject_redefinitions(child, subject_definitions.dup)
                elsif subject?(child)
                  check_subject(child, subject_definitions)
                end
              end
            end
          end

          def check_subject(subject_node, subject_definitions)
            name = name_for(subject_node)

            if subject_definitions.key?(name)
              add_offense(subject_node, message: redefined_subject_message(name, subject_definitions))
              subject_definitions[name] << line_location(subject_node)
            else
              subject_definitions[name] = [line_location(subject_node)]
            end
          end

          def redefined_subject_message(name, subject_definitions)
            format(MSG, name:, definitions: subject_definitions[name].join(', '))
          end

          def line_location(node)
            node.source_range.line
          end
        end
      end
    end
  end
end
