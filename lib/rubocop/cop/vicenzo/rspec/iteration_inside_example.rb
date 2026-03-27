# frozen_string_literal: true

module RuboCop
  module Cop
    module Vicenzo
      module RSpec
        # Do not use `expect` inside an iteration within an example.
        #
        # Placing `expect` calls inside an iteration block (e.g. `each`) makes
        # tests implicit and hard to debug: when the assertion fails it is unclear
        # which element caused the failure, and not all elements may represent the
        # same condition. Using iteration to build or transform data before calling
        # `expect` is fine; the problem is calling `expect` inside the iteration.
        # Write explicit assertions for each relevant case instead.
        #
        # @example
        #   # bad — expect is called inside the iteration
        #
        #   it 'returns vehicle costs general values' do
        #     response_body[:vehicle_costs].first.each do |attribute, value|
        #       expect(value).to eq(vehicle_cost.send(attribute).to_s)
        #     end
        #   end
        #
        #   # good — iteration builds data, expect is called once outside
        #
        #   it 'returns the expected column names' do
        #     columns = VehicleCost.column_names.map { |column| column.gsub('_centavos', '') }
        #     expect(response_body[:vehicle_costs].first.keys).to match_array(columns.map(&:to_sym))
        #   end
        #
        #   # good — each attribute has an explicit example
        #
        #   it 'returns the correct name' do
        #     expect(response_body[:vehicle_costs].first[:name]).to eq(vehicle_cost.name)
        #   end
        #
        #   it 'returns the correct value' do
        #     expect(response_body[:vehicle_costs].first[:value]).to eq(vehicle_cost.value.to_s)
        #   end
        class IterationInsideExample < RuboCop::Cop::RSpec::Base
          MSG = 'Do not call `expect` inside an iteration. ' \
                'Write explicit assertions instead.'

          ENUMERATION_METHODS = %i[each each_with_index each_with_object].freeze

          # @!method enumeration_block?(node)
          def_node_matcher :enumeration_block?, <<~PATTERN
            (block
              (send _ {#{ENUMERATION_METHODS.map(&:inspect).join(' ')}} ...)
              ...)
          PATTERN

          def on_block(node)
            return unless example?(node)

            find_iterations_with_assertions(node.body)
          end

          alias on_numblock on_block

          private

          def find_iterations_with_assertions(body)
            return unless body

            body.each_node(:block) do |iteration|
              next unless enumeration_block?(iteration)
              next unless contains_expectation?(iteration.body)

              add_offense(iteration.send_node)
            end
          end

          def contains_expectation?(node)
            return false unless node

            node.each_node(:send).any? { |send_node| send_node.method?(:expect) }
          end
        end
      end
    end
  end
end
