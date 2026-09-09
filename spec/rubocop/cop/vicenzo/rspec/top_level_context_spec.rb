# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vicenzo::RSpec::TopLevelContext, :rspec_config do
  describe 'offense detection' do
    context 'when the top-level group holds a context' do
      it 'registers an offense' do
        offense = 'This context is declared in the top-level example group, so it is a scenario for ' \
                  'every example in the file. Nest it in the group whose behaviour it is a scenario of.'

        expect_offense(<<~RUBY)
          RSpec.describe Person do
            context 'when the person is a minor' do
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense}
              it { is_expected.not_to be_adult }
            end
          end
        RUBY
      end
    end

    context 'when the context is focused' do
      it 'registers an offense' do
        offense = 'This context is declared in the top-level example group, so it is a scenario for ' \
                  'every example in the file. Nest it in the group whose behaviour it is a scenario of.'

        expect_offense(<<~RUBY)
          RSpec.describe Person do
            fcontext 'when the person is a minor' do
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense}
              it { is_expected.not_to be_adult }
            end
          end
        RUBY
      end
    end

    context 'when the top-level group holds sibling contexts' do
      it 'registers an offense on each one' do
        offense = 'This context is declared in the top-level example group, so it is a scenario for ' \
                  'every example in the file. Nest it in the group whose behaviour it is a scenario of.'

        expect_offense(<<~RUBY)
          RSpec.describe Person do
            context 'when the person is a minor' do
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense}
              it { is_expected.not_to be_adult }
            end

            context 'when the person is of age' do
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{offense}
              it { is_expected.to be_adult }
            end
          end
        RUBY
      end
    end

    context 'when the context is nested in a describe' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          RSpec.describe Person do
            describe '#adult?' do
              context 'when the person is a minor' do
                it { is_expected.not_to be_adult }
              end
            end
          end
        RUBY
      end
    end

    context 'when the top-level group holds a describe' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          RSpec.describe Person do
            describe '#adult?' do
              it { is_expected.to be_adult }
            end
          end
        RUBY
      end
    end

    context 'when the top-level group holds a shared context' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          RSpec.describe Person do
            shared_context 'with a frozen clock' do
              before { travel_to(Time.zone.local(2026, 1, 1)) }
            end
          end
        RUBY
      end
    end

    context 'when the top-level block is not an example group' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          RSpec.shared_examples 'an adult' do
            context 'when the person is a minor' do
              it { is_expected.not_to be_adult }
            end
          end
        RUBY
      end
    end
  end
end
