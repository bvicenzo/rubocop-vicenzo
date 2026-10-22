# frozen_string_literal: true

module RuboCop
  module Cop
    module Vicenzo
      module RSpec
        # Shared helpers for the cops that ask whether a definition reads the subject: which names answer to it
        # where the definition sits, and whether a call is a bare reference to one of them.
        #
        # Meant for cops inheriting from `RuboCop::Cop::RSpec::Base` and including `PremiseTracking`:
        # `example_group?` and `subject?` come from the former, `each_child_block` and `premise_name` from the
        # latter.
        module SubjectReference
          private

          # `subject` always refers to the subject, declared or implicit; a named one answers to its name
          # as well. A definition is read in every example group below the one declaring it, so the subjects
          # declared down there - the "abstract let" shape - answer too. Names come nearest group first, after
          # `subject`.
          def subject_names(node)
            names = Set[:subject]
            groups = node.each_ancestor(:any_block).select { |ancestor| example_group?(ancestor) }

            collect_subject_names(groups.first, names, nested: true) if groups.any?
            groups.drop(1).each { |group| collect_subject_names(group, names) }

            names
          end

          def collect_subject_names(group, names, nested: false)
            each_child_block(group) do |child|
              if subject?(child)
                names << subject_name(child)
              elsif nested && example_group?(child)
                collect_subject_names(child, names, nested:)
              end
            end
          end

          # An anonymous `subject!` is still read as `subject`.
          def subject_name(node)
            name = premise_name(node).to_sym

            name == :subject! ? :subject : name
          end

          def subject_reference?(receiver, names)
            return false unless receiver.send_type? && receiver.receiver.nil? && receiver.arguments.empty?

            names.include?(receiver.method_name)
          end
        end
      end
    end
  end
end
