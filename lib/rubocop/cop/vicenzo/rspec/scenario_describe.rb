# frozen_string_literal: true

require_relative 'describe_inside_context'
require_relative 'mixin/described_method'
require_relative 'mixin/premise_tracking'
require_relative 'mixin/subject_reference'

module RuboCop
  module Cop
    module Vicenzo
      module RSpec
        # A describe that exercises an entry point a sibling describe already names is a scenario of that entry
        # point, escaped into a group of its own. Make it a context inside the describe naming the entry point.
        #
        # A describe names *what* is exercised, never *when*. A scenario usually escapes because the premises of
        # the entry point's describe - a temporary directory, a `before` writing a file - did not fit it. Those
        # premises belong in the contexts that read them: move them down, and the scenario fits back in. Left
        # outside, the tree claims the entry point has fewer cases than it has, and the escaped one never states
        # its premise as a context sentence.
        #
        # Only describes that name nothing are checked: a describe naming a class, an instance method
        # (`'#name'`) or a class method (`'.name'`) states what it exercises, even when it calls another entry
        # point to build its premises. Groups such as `describe 'GET /users'`, `describe 'enums'` or
        # `describe 'callbacks'` are reported only when a sibling names the entry point they call.
        #
        # An entry point is reached by `described_class.name` (or `described_class.(...)` for `.call`) for a
        # class method, and by `subject.name`, the named subject or `described_class.new(...).name` for an
        # instance method. Calls inside a nested describe that names a class or an entry point belong to that
        # describe, so they do not count.
        #
        # @example
        #   # bad - the reference file is a scenario of `.from_file`, outside its describe
        #   RSpec.describe ImageLoader do
        #     describe '.from_file' do
        #       let(:directory) { Dir.mktmpdir }
        #
        #       after { FileUtils.remove_entry(directory) }
        #
        #       context 'when the file does not exist' do
        #         it { expect { described_class.from_file(File.join(directory, 'missing.bin')) }.to raise_error(Errno::ENOENT) }
        #       end
        #     end
        #
        #     describe 'loading the real reference file', :local_file do
        #       it { expect(described_class.from_file(reference_path)).to have_attributes(size: 393_232) }
        #     end
        #   end
        #
        #   # good - every scenario of `.from_file` is a context inside it, carrying its own premises
        #   RSpec.describe ImageLoader do
        #     describe '.from_file' do
        #       context 'when the file does not exist' do
        #         let(:directory) { Dir.mktmpdir }
        #
        #         after { FileUtils.remove_entry(directory) }
        #
        #         it { expect { described_class.from_file(File.join(directory, 'missing.bin')) }.to raise_error(Errno::ENOENT) }
        #       end
        #
        #       context 'when the file is the real reference file', :local_file do
        #         it { expect(described_class.from_file(reference_path)).to have_attributes(size: 393_232) }
        #       end
        #     end
        #   end
        class ScenarioDescribe < RuboCop::Cop::RSpec::Base
          include PremiseTracking
          include SubjectReference

          MSG = 'This `%<group>s` exercises `%<entry_point>s`, which the sibling `%<sibling>s` already names: ' \
                'make it a `context` inside that group.'

          CLASS_METHOD = '.'
          INSTANCE_METHOD = '#'

          # @!method describe_definition?(node)
          def_node_matcher :describe_definition?, <<~PATTERN
            (any_block (send #rspec? {#{DescribeInsideContext::DESCRIBES.map(&:inspect).join(' ')}} ...) ...)
          PATTERN

          # @!method described_class_reference?(node)
          def_node_matcher :described_class_reference?, '(send nil? :described_class)'

          # @!method new_instance?(node)
          def_node_matcher :new_instance?, '(send (send nil? :described_class) :new ...)'

          def on_block(node)
            return unless spec_group?(node)

            describes = child_describes(node)
            named = named_entry_points(describes)

            return if named.empty?

            describes.each { |describe| check_candidate(describe, named) }
          end

          alias on_numblock on_block

          private

          def child_describes(group)
            describes = []
            each_child_block(group) { |child| describes << child if describe_definition?(child) }
            describes
          end

          # The first sibling naming each entry point, keyed by the entry point as written: `.name` or `#name`.
          def named_entry_points(describes)
            describes.each_with_object({}) do |describe, named|
              entry_point = entry_point_named_by(describe)
              named[entry_point] ||= describe if entry_point
            end
          end

          def check_candidate(describe, named)
            return if names_something?(describe)

            entry_point = first_reached_entry_point(describe, named)
            return unless entry_point

            add_offense(describe.send_node, message: message(describe, entry_point, named[entry_point]))
          end

          # `'.from_file'`, `'#size'` and the forms carrying a signature. A bare name, such as `'call'`, could be
          # either, so it names nothing.
          def entry_point_named_by(describe)
            description = describe.send_node.first_argument
            return unless description&.str_type?

            match = DescribedMethod::PREFIXED_METHOD_DESCRIPTION.match(description.value)
            "#{description.value[0]}#{match[:name]}" if match
          end

          # A class changes what `described_class` is below it, and an entry point is what the group exercises:
          # either way, the group states what it is about.
          def names_something?(describe)
            describe.send_node.first_argument&.const_type? || !entry_point_named_by(describe).nil?
          end

          # Walks the group in source order, leaving out the nested describes that name something: what is
          # called there belongs to them.
          def first_reached_entry_point(node, named)
            node.each_child_node do |child|
              next if describe_definition?(child) && names_something?(child)

              entry_point = reached_entry_point(child, named) || first_reached_entry_point(child, named)
              return entry_point if entry_point
            end

            nil
          end

          def reached_entry_point(node, named)
            return unless node.call_type? && node.receiver

            class_method = "#{CLASS_METHOD}#{node.method_name}"
            instance_method = "#{INSTANCE_METHOD}#{node.method_name}"

            if named.has_key?(class_method) && described_class_reference?(node.receiver)
              class_method
            elsif named.has_key?(instance_method) && instance_receiver?(node)
              instance_method
            end
          end

          def instance_receiver?(node)
            new_instance?(node.receiver) || subject_reference?(node.receiver, subject_names(node))
          end

          def message(describe, entry_point, sibling)
            sibling_send = sibling.send_node

            format(
              MSG,
              group: describe.method_name,
              entry_point:,
              sibling: "#{sibling_send.method_name} #{sibling_send.first_argument.source}"
            )
          end
        end
      end
    end
  end
end
