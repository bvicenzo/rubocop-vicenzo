# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vicenzo::RSpec::IterationInsideExample, :rspec_config do
  context 'when expect is called inside an each block within an example' do
    it 'registers an offense on the iteration call' do
      expect_offense(<<~RUBY)
        it 'returns all attributes' do
          response.first.each do |attribute, value|
          ^^^^^^^^^^^^^^^^^^^ Do not call `expect` inside an iteration. Write explicit assertions instead.
            expect(value).to eq(record.send(attribute).to_s)
          end
        end
      RUBY
    end
  end

  context 'when expect is called inside an each_with_index block within an example' do
    it 'registers an offense on the iteration call' do
      expect_offense(<<~RUBY)
        it 'returns items in order' do
          results.each_with_index do |result, position|
          ^^^^^^^^^^^^^^^^^^^^^^^ Do not call `expect` inside an iteration. Write explicit assertions instead.
            expect(result[:position]).to eq(position)
          end
        end
      RUBY
    end
  end

  context 'when expect is called inside an each_with_object block within an example' do
    it 'registers an offense on the iteration call' do
      expect_offense(<<~RUBY)
        it 'processes each item' do
          items.each_with_object({}) do |item, accumulator|
          ^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not call `expect` inside an iteration. Write explicit assertions instead.
            expect(item).to be_valid
          end
        end
      RUBY
    end
  end

  context 'when iteration is used to build data and expect is called outside' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        it 'returns the expected column names' do
          columns = VehicleCost.column_names.map { |column| column.gsub('_centavos', '') }
          expect(response.first.keys).to match_array(columns.map(&:to_sym))
        end
      RUBY
    end
  end

  context 'when iteration is used inside a before hook' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        before do
          roles.each do |role|
            expect(role).to be_valid
          end
        end
      RUBY
    end
  end

  context 'when iteration is used at example group level (outside an example)' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        [:admin, :driver].each do |role|
          context "when role is \#{role}" do
            it 'does something' do
            end
          end
        end
      RUBY
    end
  end

  context 'when iteration inside an example does not contain expect' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        it 'processes roles' do
          roles.each do |role|
            setup(role)
          end

          expect(result).to be_success
        end
      RUBY
    end
  end

  context 'when specify is used instead of it' do
    it 'registers an offense on the iteration call' do
      expect_offense(<<~RUBY)
        specify 'returns all attributes' do
          response.first.each do |attribute, value|
          ^^^^^^^^^^^^^^^^^^^ Do not call `expect` inside an iteration. Write explicit assertions instead.
            expect(value).to eq(record.send(attribute).to_s)
          end
        end
      RUBY
    end
  end
end
