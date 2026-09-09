# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vicenzo::RSpec::TopLevelHook, :rspec_config do
  describe 'offense detection' do
    context 'when the top-level group declares a before hook' do
      it 'registers an offense' do
        offense = 'Hook `before` is declared in the top-level example group, so it runs for every ' \
                  'example in the file. Declare it in the group whose examples need it.'

        expect_offense(<<~RUBY)
          RSpec.describe Person do
            before { travel_to(Time.zone.local(2026, 1, 1)) }
            ^^^^^^ #{offense}

            describe '#adult?' do
              it { is_expected.to be_adult }
            end
          end
        RUBY
      end
    end

    context 'when the hook is scoped to each example' do
      it 'registers an offense' do
        offense = 'Hook `before` is declared in the top-level example group, so it runs for every ' \
                  'example in the file. Declare it in the group whose examples need it.'

        expect_offense(<<~RUBY)
          RSpec.describe Person do
            before(:each) { travel_to(Time.zone.local(2026, 1, 1)) }
            ^^^^^^^^^^^^^ #{offense}

            describe '#adult?' do
              it { is_expected.to be_adult }
            end
          end
        RUBY
      end
    end

    context 'when the top-level group declares an after hook' do
      it 'registers an offense' do
        offense = 'Hook `after` is declared in the top-level example group, so it runs for every ' \
                  'example in the file. Declare it in the group whose examples need it.'

        expect_offense(<<~RUBY)
          RSpec.describe Person do
            after { travel_back }
            ^^^^^ #{offense}

            describe '#adult?' do
              it { is_expected.to be_adult }
            end
          end
        RUBY
      end
    end

    context 'when the top-level group declares an around hook' do
      it 'registers an offense' do
        offense = 'Hook `around` is declared in the top-level example group, so it runs for every ' \
                  'example in the file. Declare it in the group whose examples need it.'

        expect_offense(<<~RUBY)
          RSpec.describe Person do
            around { |example| travel_to(Time.zone.local(2026, 1, 1)) { example.run } }
            ^^^^^^ #{offense}

            describe '#adult?' do
              it { is_expected.to be_adult }
            end
          end
        RUBY
      end
    end

    context 'when the hook is declared in a nested describe' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          RSpec.describe Person do
            describe '#adult?' do
              before { travel_to(Time.zone.local(2026, 1, 1)) }

              it { is_expected.to be_adult }
            end
          end
        RUBY
      end
    end

    context 'when the hook is declared in a nested context' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          RSpec.describe Person do
            describe '#adult?' do
              context 'when the clock is frozen' do
                before { travel_to(Time.zone.local(2026, 1, 1)) }

                it { is_expected.to be_adult }
              end
            end
          end
        RUBY
      end
    end

    context 'when the hook is declared in shared examples nested in the top-level group' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          RSpec.describe Person do
            shared_examples 'an adult' do
              before { travel_to(Time.zone.local(2026, 1, 1)) }

              it { is_expected.to be_adult }
            end
          end
        RUBY
      end
    end

    context 'when the top-level block is not an example group' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          RSpec.shared_examples 'an adult' do
            before { travel_to(Time.zone.local(2026, 1, 1)) }

            it { is_expected.to be_adult }
          end
        RUBY
      end
    end
  end
end
