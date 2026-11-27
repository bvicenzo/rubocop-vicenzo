# frozen_string_literal: true

module RuboCop
  module Cop
    module Vicenzo
      module RSpec
        # Do not share premises through a shared context. Declare them in the scenario that reads them, and
        # share only a complete behaviour, the same for every group, through shared examples.
        #
        # A shared context starts as a handful of premises a few groups happen to need. Then one group
        # needs a premise slightly different, and instead of declaring its own, it bends the shared one: a
        # parameter, an `if`, a `case`, a `let` overridden from the outside. Every bend is a scenario
        # hidden inside the shared context, coupling specs that have nothing to do with each other, and
        # the reader of a group can no longer see what the group starts from without opening another file
        # and replaying its branches.
        #
        # Shared examples are a different thing when they assert a whole behaviour that holds the same for
        # every group including them, such as being timestamped or auditable. That is sharing a contract,
        # not premises.
        #
        # Tests do not have to be DRY; the code does. Repeating a premise in each scenario that reads it
        # keeps every scenario whole and free to change on its own.
        #
        # Both the definition (`shared_context`) and every inclusion (`include_context`) are reported:
        # the definition is the one to remove, and each inclusion is where its premises have to land.
        #
        # @example
        #   # bad - premises shared across scenarios
        #   RSpec.shared_context 'with an active subscription' do
        #     let(:plan) { create(:plan, :monthly) }
        #     let(:subscription) { create(:subscription, plan:, status: :active) }
        #   end
        #
        #   RSpec.describe Invoice do
        #     describe '#total' do
        #       context 'when the subscription is active' do
        #         include_context 'with an active subscription'
        #
        #         it { expect(invoice.total).to eq(100) }
        #       end
        #     end
        #   end
        #
        #   # good - the scenario declares what it starts from
        #   RSpec.describe Invoice do
        #     describe '#total' do
        #       context 'when the subscription is active' do
        #         let(:subscription) { create(:subscription, plan: create(:plan, :monthly), status: :active) }
        #
        #         it { expect(invoice.total).to eq(100) }
        #       end
        #     end
        #   end
        #
        #   # good - a complete behaviour, the same for every group including it
        #   RSpec.shared_examples 'a timestamped record' do
        #     it { is_expected.to respond_to(:created_at) }
        #     it { is_expected.to respond_to(:updated_at) }
        #   end
        #
        # @example AllowedContexts: ['with a frozen clock']
        #   # good - an infrastructure context allowed by name
        #   RSpec.shared_context 'with a frozen clock' do
        #     around { |example| travel_to(Time.zone.local(2026, 1, 1)) { example.run } }
        #   end
        #
        #   RSpec.describe Invoice do
        #     include_context 'with a frozen clock'
        #   end
        class SharedPremises < RuboCop::Cop::RSpec::Base
          DEFINITION_MSG = 'Shared context `%<name>s` shares premises across scenarios. Declare them in each ' \
                           'scenario that reads them; share only a complete behaviour, the same for every ' \
                           'group, through shared examples. Tests do not have to be DRY; the code does.'

          INCLUSION_MSG = '`%<method>s` pulls premises from shared context `%<name>s`. Declare them in this ' \
                          'scenario, so it reads whole and changes without branching the shared context. ' \
                          'Tests do not have to be DRY; the code does.'

          # @!method shared_context_definition(node)
          def_node_matcher :shared_context_definition, <<~PATTERN
            (any_block $(send #rspec? #SharedGroups.context $_ ...) ...)
          PATTERN

          # @!method shared_context_inclusion(node)
          def_node_matcher :shared_context_inclusion, <<~PATTERN
            (send nil? #Includes.context $_ ...)
          PATTERN

          def on_block(node)
            shared_context_definition(node) do |send_node, name|
              next if allowed_context?(name)

              add_offense(send_node, message: format(DEFINITION_MSG, name: context_name(name)))
            end
          end
          alias on_numblock on_block

          def on_send(node)
            shared_context_inclusion(node) do |name|
              next if allowed_context?(name)

              add_offense(node, message: format(INCLUSION_MSG, method: node.method_name, name: context_name(name)))
            end
          end
          alias on_csend on_send

          private

          def allowed_context?(name) = allowed_contexts.include?(context_name(name))

          def context_name(name) = name.respond_to?(:value) ? name.value.to_s : name.source

          def allowed_contexts
            cop_config.fetch('AllowedContexts', [])
          end
        end
      end
    end
  end
end
