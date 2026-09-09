# frozen_string_literal: true

require_relative 'mixin/top_level_definition'

module RuboCop
  module Cop
    module Vicenzo
      module RSpec
        # A hook declared straight inside the top-level example group runs for every example in the
        # file. Declare it in the group whose examples need it.
        #
        # A hook is a premise like any other - it just builds the state through side effects instead of
        # a name. Declared at the root it reaches every example, including the ones written later that
        # never asked for that state, and the group that needs the state built differently can only
        # undo it, override it, or work around it.
        #
        # It is also the escape hatch left open once the root cannot hold a `subject` or a `let` any
        # more: the premise stops being declared and starts being performed, which is harder to read and
        # invisible to the cops that watch definitions. `Vicenzo/RSpec/TopLevelSubject` and
        # `Vicenzo/RSpec/TopLevelLet` close the front door; this one closes the back.
        #
        # @example
        #   # bad - every example in the file runs inside this state
        #   RSpec.describe Person do
        #     before { travel_to(Time.zone.local(2026, 1, 1)) }
        #
        #     describe '#adult?' do
        #       it { is_expected.to be_adult }
        #     end
        #   end
        #
        #   # good - the state belongs to the examples that need it
        #   RSpec.describe Person do
        #     describe '#adult?' do
        #       before { travel_to(Time.zone.local(2026, 1, 1)) }
        #
        #       it { is_expected.to be_adult }
        #     end
        #   end
        class TopLevelHook < RuboCop::Cop::RSpec::Base
          include TopLevelDefinition

          MSG = 'Hook `%<name>s` is declared in the top-level example group, so it runs for every ' \
                'example in the file. Declare it in the group whose examples need it.'

          private

          def message_for(node) = format(MSG, name: node.method_name)

          def definition?(node) = hook?(node)
        end
      end
    end
  end
end
