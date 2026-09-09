# frozen_string_literal: true

require_relative 'mixin/top_level_definition'

module RuboCop
  module Cop
    module Vicenzo
      module RSpec
        # A subject declared straight inside the top-level example group is the root of the nested
        # redefinition problem. Declare it in the group whose examples read it.
        #
        # The top-level group is the widest scope a file has: a subject born there is handed to every
        # example, including all the ones written later that were never considered when it was written.
        # The first sibling group that needs the object built slightly differently has nowhere to go but
        # over the top of it - a redefinition, a second subject under another name, or a `before` that
        # patches the object back into shape. None of those read as a specification any more, and each
        # one is a scenario nobody named.
        #
        # Declaring the subject in the group that asserts on it costs one extra line per group and buys
        # back the naming: each group states the object it is about, and a sibling that needs a different
        # object is a different group with its own declaration, not an override of someone else's.
        #
        # This is the preventive half of `Vicenzo/RSpec/NestedSubjectRedefinition`, which reports the
        # redefinition once it exists. Keeping the top-level group free of subjects means there is
        # nothing to redefine.
        #
        # @example
        #   # bad - the subject reaches every example, so `#tall?` can only override it
        #   RSpec.describe Person do
        #     subject(:person) { described_class.new }
        #
        #     describe '#adult?' do
        #       before { person.age = 18 }
        #
        #       it { is_expected.to be_adult }
        #     end
        #
        #     describe '#tall?' do
        #       subject(:person) { described_class.new(height: 1.75) }
        #
        #       it { is_expected.to be_tall }
        #     end
        #   end
        #
        #   # good - each group declares the person its examples are about
        #   RSpec.describe Person do
        #     describe '#adult?' do
        #       subject(:person) { described_class.new(age: 18) }
        #
        #       it { is_expected.to be_adult }
        #     end
        #
        #     describe '#tall?' do
        #       subject(:person) { described_class.new(height: 1.75) }
        #
        #       it { is_expected.to be_tall }
        #     end
        #   end
        #
        # @example a context is as good a home as a describe
        #   # good - the subject belongs to the scenario, and the scenario is a context
        #   RSpec.describe Person do
        #     describe '#adult?' do
        #       context 'when the person is of age' do
        #         subject(:person) { described_class.new(age: 18) }
        #
        #         it { is_expected.to be_adult }
        #       end
        #     end
        #   end
        class TopLevelSubject < RuboCop::Cop::RSpec::Base
          include TopLevelDefinition

          MSG = 'Subject `:%<name>s` is declared in the top-level example group, where it reaches every ' \
                'example in the file. Declare it in the group whose examples read it.'
          MSG_UNNAMED = 'The subject is declared in the top-level example group, where it reaches every ' \
                        'example in the file. Declare it in the group whose examples read it.'

          private

          def message_for(node)
            name = declared_name(node)

            name.nil? ? MSG_UNNAMED : format(MSG, name:)
          end

          def definition?(node) = subject?(node)
        end
      end
    end
  end
end
