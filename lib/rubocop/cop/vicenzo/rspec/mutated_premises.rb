# frozen_string_literal: true

require_relative 'mixin/premise_tracking'

module RuboCop
  module Cop
    module Vicenzo
      module RSpec
        # Do not mutate the premises of an example.
        #
        # A `let`, `let_it_be` or `subject` is the premise a reader assumes true when reading the file. Mutating it
        # somewhere else breaks that in two ways:
        #
        # 1. The file lies. You read `let(:params) { { name: 'Ada' } }`, run it, and the value is different — the
        #    explanation is a `before` dozens of lines away.
        # 2. It breeds flakiness. `let` is lazy, so whichever example materialises it first decides the final state.
        #    A context that touches the premises in another order silently changes the result.
        #
        # Persisting changes while building a premise is flagged wherever it happens inside the definition, including
        # inline forms such as `tap`, because a factory trait or transient is always available instead. Collection
        # mutations and attribute writers are flagged when they change a premise declared in an ancestor group, so
        # building a local value inside the definition itself stays allowed.
        #
        # Examples are not inspected: there the mutation usually *is* the behaviour under test.
        #
        # @example
        #   # bad — persisting while building the premise
        #
        #   let(:order) { create(:order).tap { |record| record.update!(status: :shipped) } }
        #
        #   # bad — the same laziness spelled out
        #
        #   let(:order) do
        #     order = create(:order)
        #     order.update_column(:status, :shipped)
        #     order
        #   end
        #
        #   # good — the factory owns it
        #
        #   let(:order) { create(:order, :shipped) }
        #
        # @example
        #   # bad — the hook rewrites the premise
        #
        #   let(:params) { { name: 'Ada' } }
        #   before { params[:age] = 10 }
        #
        #   # bad — patching a record the premise built
        #
        #   before { order.shipment.update!(carrier:) }
        #
        #   # good — each context declares its complete premise
        #
        #   context 'when the age is informed' do
        #     let(:params) { { name: 'Ada', age: 10 } }
        #   end
        #
        #   # good — creation order lets the production code do the wiring
        #
        #   before do
        #     carrier
        #     order
        #   end
        #
        # @example
        #   # good — local builder, the value is born and dies inside the premise
        #
        #   let(:csv_content) { CSV.generate { |csv| csv << header } }
        class MutatedPremises < RuboCop::Cop::RSpec::Base
          include PremiseTracking

          MSG_MUTATION = 'Do not mutate the premise `%<name>s`. Declare the final state where it is needed — ' \
                         'factory trait, factory transient, or creation order.'
          MSG_PERSISTENCE = 'Do not persist changes while building `%<name>s`. Move it to a factory ' \
                            'trait/transient, or declare the final state in the context that needs it.'

          PERSISTENCE_METHODS = %i[
            update update! update_attribute update_column update_columns save save! destroy destroy! touch
            increment! decrement! toggle!
          ].freeze

          COLLECTION_METHODS = %i[<< push concat unshift store merge! deep_merge! clear delete].freeze

          def on_block(node)
            return unless example_group?(node) && outermost_example_group?(node)

            walk_example_group(node, all_premises(node))
          end

          alias on_numblock on_block

          private

          def on_premise(node, premises)
            name = premise_name(node)

            mutating_calls(node).each do |call|
              if persisting?(call)
                add_offense(call, message: format(MSG_PERSISTENCE, name:))
              else
                check_premise_mutation(call, premises)
              end
            end
          end

          def on_setup_hook(node, premises)
            mutating_calls(node).each do |call|
              next unless persisting?(call) || mutating_collection?(call)

              check_premise_mutation(call, premises)
            end
          end

          def check_premise_mutation(call, premises)
            return unless persisting?(call) || mutating_collection?(call)

            mutated_premise = premise_receiver(call, premises)

            return if mutated_premise.nil?

            add_offense(call, message: format(MSG_MUTATION, name: mutated_premise))
          end

          # `FileUtils.touch(path)` and friends act on a class, never on a premise.
          def persisting?(call)
            PERSISTENCE_METHODS.include?(call.method_name) && !call.receiver&.const_type?
          end

          def mutating_collection?(call)
            COLLECTION_METHODS.include?(call.method_name) || assignment?(call)
          end

          # Covers both `params[:age] = 10` (`:[]=`) and `record.status = :done` (`:status=`).
          def assignment?(call) = call.assignment_method? && !call.receiver.nil?
        end
      end
    end
  end
end
