# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vicenzo::RSpec::DerivedPremises, :rspec_config do
  context 'when a premise is derived from another premise through merge' do
    it 'registers an offense naming both premises' do
      expect_offense(<<~RUBY)
        describe Registration do
          let(:base_params) { { name: 'Ada' } }
          let(:params) { base_params.merge(age: 10) }
                         ^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not derive the premise `params` from `base_params`. Declare the complete value in the context that needs it.
        end
      RUBY
    end
  end

  context 'when a premise is derived from a premise declared in an ancestor group' do
    it 'registers an offense on the deriving call' do
      expect_offense(<<~RUBY)
        describe Registration do
          let(:base_params) { { name: 'Ada' } }

          context 'when the age is unknown' do
            let(:params) { base_params.except(:age) }
                           ^^^^^^^^^^^^^^^^^^^^^^^^ Do not derive the premise `params` from `base_params`. Declare the complete value in the context that needs it.
          end
        end
      RUBY
    end
  end

  context 'when a premise is derived from a premise declared in a descendant group' do
    it 'registers an offense on the deriving call' do
      expect_offense(<<~RUBY)
        describe Registration do
          let(:params) { base_params.merge(age: 10) }
                         ^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not derive the premise `params` from `base_params`. Declare the complete value in the context that needs it.

          context 'when the name is missing' do
            let(:base_params) { {} }
          end
        end
      RUBY
    end
  end

  context 'when a premise is derived from another premise through dup' do
    it 'registers an offense on the deriving call' do
      expect_offense(<<~RUBY)
        describe Registration do
          let(:original_headers) { { 'Accept' => 'application/json' } }
          let(:headers) { original_headers.dup }
                          ^^^^^^^^^^^^^^^^^^^^ Do not derive the premise `headers` from `original_headers`. Declare the complete value in the context that needs it.
        end
      RUBY
    end
  end

  context 'when a premise is derived from a factory' do
    it 'registers no offense' do
      expect_no_offenses(<<~RUBY)
        describe Order do
          let(:params) { attributes_for(:order).merge(value: 10) }
        end
      RUBY
    end
  end

  context 'when a premise merges a literal into a literal' do
    it 'registers no offense' do
      expect_no_offenses(<<~RUBY)
        describe Registration do
          let(:params) { { name: 'Ada' }.merge(age: 10) }
        end
      RUBY
    end
  end

  context 'when an example derives a value from a premise' do
    it 'registers no offense' do
      expect_no_offenses(<<~RUBY)
        describe Registration do
          let(:params) { { name: 'Ada' } }

          it 'rejects an unknown attribute' do
            expect(described_class.new(params.merge(unknown: true))).not_to be_valid
          end
        end
      RUBY
    end
  end
end
