# frozen_string_literal: true

require_relative 'mixin/top_level_definition'

module RuboCop
  module Cop
    module Vicenzo
      module RSpec
        # An example declared straight inside the top-level example group is about no behaviour in
        # particular. Move it into the group describing the behaviour it exercises.
        #
        # The top-level group names the object under test, not one of the things it does. An example
        # hanging directly off it therefore reads as a statement about the object as a whole, when it is
        # always a statement about one behaviour - the group naming that behaviour is simply missing, and
        # with it the place where the next example about the same behaviour would go.
        #
        # It is also the shape that keeps premises in the top-level group alive: as long as examples live
        # at the root, the subject and the lets they read have nowhere else to be declared, which is what
        # `Vicenzo/RSpec/TopLevelSubject` and `Vicenzo/RSpec/TopLevelLet` report.
        #
        # @example
        #   # bad - the example is about `#adult?`, but no group says so
        #   RSpec.describe Person do
        #     it { is_expected.to be_adult }
        #   end
        #
        #   # good - the behaviour the example is about has a name, and a home
        #   RSpec.describe Person do
        #     describe '#adult?' do
        #       subject(:person) { described_class.new(age: 18) }
        #
        #       it { is_expected.to be_adult }
        #     end
        #   end
        class TopLevelExample < RuboCop::Cop::RSpec::Base
          include TopLevelDefinition

          MSG = 'This example is declared in the top-level example group, which names no behaviour. ' \
                'Move it into the group describing the behaviour it exercises.'

          private

          def definition?(node) = example?(node)
        end
      end
    end
  end
end
