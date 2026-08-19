# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vicenzo::RSpec::MutatedPremises, :rspec_config do
  context 'when a premise definition persists changes inline' do
    it 'registers an offense on the persisting call' do
      expect_offense(<<~RUBY)
        describe Order do
          let(:order) { create(:order).tap { |record| record.update!(status: :shipped) } }
                                                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not persist changes while building `order`. Move it to a factory trait/transient, or declare the final state in the context that needs it.
        end
      RUBY
    end
  end

  context 'when a premise definition persists changes over a local variable' do
    it 'registers an offense on the persisting call' do
      expect_offense(<<~RUBY)
        describe Order do
          let(:order) do
            order = create(:order)
            order.update_column(:status, :shipped)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not persist changes while building `order`. Move it to a factory trait/transient, or declare the final state in the context that needs it.
            order
          end
        end
      RUBY
    end
  end

  context 'when a named subject definition persists changes' do
    it 'registers an offense naming the subject' do
      expect_offense(<<~RUBY)
        describe Order do
          subject(:order) { create(:order).save! }
                            ^^^^^^^^^^^^^^^^^^^^ Do not persist changes while building `order`. Move it to a factory trait/transient, or declare the final state in the context that needs it.
        end
      RUBY
    end
  end

  context 'when a setup hook writes into a premise' do
    it 'registers an offense on the assignment' do
      expect_offense(<<~RUBY)
        describe Registration do
          let(:params) { { name: 'Ada' } }

          before { params[:age] = 10 }
                   ^^^^^^^^^^^^^^^^^ Do not mutate the premise `params`. Declare the final state where it is needed — factory trait, factory transient, or creation order.
        end
      RUBY
    end
  end

  context 'when a setup hook persists changes through a premise association' do
    it 'registers an offense naming the premise the chain starts from' do
      expect_offense(<<~RUBY)
        describe Order do
          let(:order) { create(:order) }

          before { order.shipment.update!(carrier: carrier) }
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not mutate the premise `order`. Declare the final state where it is needed — factory trait, factory transient, or creation order.
        end
      RUBY
    end
  end

  context 'when a setup hook mutates a premise declared in an ancestor group' do
    it 'registers an offense on the mutation' do
      expect_offense(<<~RUBY)
        describe Registration do
          let(:params) { { name: 'Ada' } }

          context 'when the age is informed' do
            before { params.merge!(age: 10) }
                     ^^^^^^^^^^^^^^^^^^^^^^ Do not mutate the premise `params`. Declare the final state where it is needed — factory trait, factory transient, or creation order.
          end
        end
      RUBY
    end
  end

  context 'when a premise definition mutates another premise' do
    it 'registers an offense naming the mutated premise' do
      expect_offense(<<~RUBY)
        describe Registration do
          let(:headers) { { 'Accept' => 'application/json' } }
          let(:authorized_headers) { headers.store('Token', 'abc') }
                                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not mutate the premise `headers`. Declare the final state where it is needed — factory trait, factory transient, or creation order.
        end
      RUBY
    end
  end

  context 'when a setup hook mutates a premise declared in a descendant group' do
    it 'registers an offense on the mutation' do
      expect_offense(<<~RUBY)
        describe Registration do
          before { params[:age] = 10 }
                   ^^^^^^^^^^^^^^^^^ Do not mutate the premise `params`. Declare the final state where it is needed — factory trait, factory transient, or creation order.

          context 'when the name is informed' do
            let(:params) { { name: 'Ada' } }
          end
        end
      RUBY
    end
  end

  context 'when an example mutates a premise' do
    it 'registers no offense, since there the mutation is the behaviour under test' do
      expect_no_offenses(<<~RUBY)
        describe Order do
          let(:order) { create(:order) }

          it 'ships the order' do
            expect { order.update!(status: :shipped) }.to change(order, :status)
          end
        end
      RUBY
    end
  end

  context 'when an after hook mutates a premise' do
    it 'registers no offense, since teardown is not a premise' do
      expect_no_offenses(<<~RUBY)
        describe Order do
          let(:order) { create(:order) }

          after { order.destroy! }
        end
      RUBY
    end
  end

  context 'when a premise definition builds a local value through a collection method' do
    it 'registers no offense' do
      expect_no_offenses(<<~RUBY)
        describe Report do
          let(:csv_content) { CSV.generate { |csv| csv << header } }
        end
      RUBY
    end
  end

  context 'when a setup hook only materialises premises' do
    it 'registers no offense' do
      expect_no_offenses(<<~RUBY)
        describe Order do
          let(:carrier) { create(:carrier) }
          let(:order) { create(:order) }

          before do
            carrier
            order
          end
        end
      RUBY
    end
  end

  context 'when a setup hook persists changes over something that is not a premise' do
    it 'registers no offense' do
      expect_no_offenses(<<~RUBY)
        describe Order do
          before { create(:configuration).update!(enabled: true) }
        end
      RUBY
    end
  end

  context 'when a premise definition calls a persistence method on a class' do
    it 'registers no offense' do
      expect_no_offenses(<<~RUBY)
        describe Report do
          let(:file) { FileUtils.touch(path) }
        end
      RUBY
    end
  end
end
