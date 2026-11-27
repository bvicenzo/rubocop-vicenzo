# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vicenzo::RSpec::SharedPremises, :rspec_config do
  describe 'offense detection' do
    context 'when a shared context is defined' do
      context 'and it is called without a receiver' do
        it 'registers an offense' do
          offense = 'Shared context `with an active subscription` shares premises across scenarios. Declare ' \
                    'them in each scenario that reads them; share only a complete behaviour, the same for ' \
                    'every group, through shared examples. Tests do not have to be DRY; the code does.'

          expect_offense(<<~RUBY)
            shared_context 'with an active subscription' do
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense}
              let(:subscription) { create(:subscription, status: :active) }
            end
          RUBY
        end
      end

      context 'and it is called on RSpec' do
        it 'registers an offense' do
          offense = 'Shared context `with an active subscription` shares premises across scenarios. Declare ' \
                    'them in each scenario that reads them; share only a complete behaviour, the same for ' \
                    'every group, through shared examples. Tests do not have to be DRY; the code does.'

          expect_offense(<<~RUBY)
            RSpec.shared_context 'with an active subscription' do
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense}
              let(:subscription) { create(:subscription, status: :active) }
            end
          RUBY
        end
      end

      context 'and it carries metadata' do
        it 'registers an offense' do
          offense = 'Shared context `with an active subscription` shares premises across scenarios. Declare ' \
                    'them in each scenario that reads them; share only a complete behaviour, the same for ' \
                    'every group, through shared examples. Tests do not have to be DRY; the code does.'

          expect_offense(<<~RUBY)
            shared_context 'with an active subscription', :billing do
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense}
              let(:subscription) { create(:subscription, status: :active) }
            end
          RUBY
        end
      end

      context 'and its name is a symbol' do
        it 'registers an offense' do
          offense = 'Shared context `active_subscription` shares premises across scenarios. Declare them in ' \
                    'each scenario that reads them; share only a complete behaviour, the same for every ' \
                    'group, through shared examples. Tests do not have to be DRY; the code does.'

          expect_offense(<<~RUBY)
            shared_context :active_subscription do
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense}
              let(:subscription) { create(:subscription, status: :active) }
            end
          RUBY
        end
      end

      context 'and its name is a constant' do
        it 'registers an offense' do
          offense = 'Shared context `ActiveSubscription` shares premises across scenarios. Declare them in ' \
                    'each scenario that reads them; share only a complete behaviour, the same for every ' \
                    'group, through shared examples. Tests do not have to be DRY; the code does.'

          expect_offense(<<~RUBY)
            shared_context ActiveSubscription do
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense}
              let(:subscription) { create(:subscription, status: :active) }
            end
          RUBY
        end
      end
    end

    context 'when a shared context is included' do
      context 'and the inclusion has no block' do
        it 'registers an offense' do
          offense = '`include_context` pulls premises from shared context `with an active subscription`. ' \
                    'Declare them in this scenario, so it reads whole and changes without branching the ' \
                    'shared context. Tests do not have to be DRY; the code does.'

          expect_offense(<<~RUBY)
            RSpec.describe Invoice do
              describe '#total' do
                context 'when the subscription is active' do
                  include_context 'with an active subscription'
                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense}

                  it { expect(invoice.total).to eq(100) }
                end
              end
            end
          RUBY
        end
      end

      context 'and the inclusion overrides premises in a block' do
        it 'registers an offense' do
          offense = '`include_context` pulls premises from shared context `with an active subscription`. ' \
                    'Declare them in this scenario, so it reads whole and changes without branching the ' \
                    'shared context. Tests do not have to be DRY; the code does.'

          expect_offense(<<~RUBY)
            RSpec.describe Invoice do
              describe '#total' do
                context 'when the subscription is active' do
                  include_context 'with an active subscription' do
                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense}
                    let(:plan) { create(:plan, :yearly) }
                  end

                  it { expect(invoice.total).to eq(100) }
                end
              end
            end
          RUBY
        end
      end
    end

    context 'when shared examples are defined' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          RSpec.shared_examples 'a timestamped record' do
            it { is_expected.to respond_to(:created_at) }
            it { is_expected.to respond_to(:updated_at) }
          end
        RUBY
      end
    end

    context 'when shared examples are included' do
      context 'and they are included with it_behaves_like' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            RSpec.describe Person do
              it_behaves_like 'a timestamped record'
            end
          RUBY
        end
      end

      context 'and they are included with include_examples' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            RSpec.describe Person do
              include_examples 'a timestamped record'
            end
          RUBY
        end
      end
    end

    context 'when a shared context is included on a receiver' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          RSpec.configure do |config|
            config.include_context 'with a frozen clock', :frozen_clock
          end
        RUBY
      end
    end

    context 'when shared_context is called on a receiver other than RSpec' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          Billing.shared_context 'with an active subscription' do
            let(:subscription) { create(:subscription, status: :active) }
          end
        RUBY
      end
    end

    context 'when AllowedContexts is configured' do
      let(:cop_config) { { 'AllowedContexts' => ['with a frozen clock', 'frozen_clock'] } }

      context 'but the shared context is not in the list' do
        context 'and it is defined' do
          it 'registers an offense' do
            offense = 'Shared context `with an active subscription` shares premises across scenarios. Declare ' \
                      'them in each scenario that reads them; share only a complete behaviour, the same for ' \
                      'every group, through shared examples. Tests do not have to be DRY; the code does.'

            expect_offense(<<~RUBY)
              shared_context 'with an active subscription' do
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense}
                let(:subscription) { create(:subscription, status: :active) }
              end
            RUBY
          end
        end

        context 'and it is included' do
          it 'registers an offense' do
            offense = '`include_context` pulls premises from shared context `with an active subscription`. ' \
                      'Declare them in this scenario, so it reads whole and changes without branching the ' \
                      'shared context. Tests do not have to be DRY; the code does.'

            expect_offense(<<~RUBY)
              RSpec.describe Invoice do
                include_context 'with an active subscription'
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense}
              end
            RUBY
          end
        end
      end

      context 'and the shared context is in the list' do
        context 'and it is defined' do
          it 'does not register an offense' do
            expect_no_offenses(<<~RUBY)
              shared_context 'with a frozen clock' do
                around { |example| travel_to(Time.zone.local(2026, 1, 1)) { example.run } }
              end
            RUBY
          end
        end

        context 'and it is included' do
          it 'does not register an offense' do
            expect_no_offenses(<<~RUBY)
              RSpec.describe Invoice do
                include_context 'with a frozen clock'
              end
            RUBY
          end
        end

        context 'and it is included by a symbol name' do
          it 'does not register an offense' do
            expect_no_offenses(<<~RUBY)
              RSpec.describe Invoice do
                include_context :frozen_clock
              end
            RUBY
          end
        end
      end
    end
  end
end
