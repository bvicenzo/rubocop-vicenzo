# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vicenzo::RSpec::TopLevelExample, :rspec_config do
  describe 'offense detection' do
    context 'when the top-level group holds a one-liner example' do
      it 'registers an offense' do
        offense = 'This example is declared in the top-level example group, which names no behaviour. ' \
                  'Move it into the group describing the behaviour it exercises.'

        expect_offense(<<~RUBY)
          RSpec.describe Person do
            it { is_expected.to be_adult }
            ^^ #{offense}
          end
        RUBY
      end
    end

    context 'when the top-level group holds a documented example' do
      it 'registers an offense' do
        offense = 'This example is declared in the top-level example group, which names no behaviour. ' \
                  'Move it into the group describing the behaviour it exercises.'

        expect_offense(<<~RUBY)
          RSpec.describe Person do
            it 'is an adult' do
            ^^^^^^^^^^^^^^^^ #{offense}
              expect(described_class.new(age: 18)).to be_adult
            end
          end
        RUBY
      end
    end

    context 'when the example is written with specify' do
      it 'registers an offense' do
        offense = 'This example is declared in the top-level example group, which names no behaviour. ' \
                  'Move it into the group describing the behaviour it exercises.'

        expect_offense(<<~RUBY)
          RSpec.describe Person do
            specify { is_expected.to be_adult }
            ^^^^^^^ #{offense}
          end
        RUBY
      end
    end

    context 'when the top-level group holds several examples' do
      it 'registers an offense on each one' do
        offense = 'This example is declared in the top-level example group, which names no behaviour. ' \
                  'Move it into the group describing the behaviour it exercises.'

        expect_offense(<<~RUBY)
          RSpec.describe Person do
            it { is_expected.to be_adult }
            ^^ #{offense}
            it { is_expected.to be_tall }
            ^^ #{offense}
          end
        RUBY
      end
    end

    context 'when the example is declared in a nested describe' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          RSpec.describe Person do
            describe '#adult?' do
              subject(:person) { described_class.new(age: 18) }

              it { is_expected.to be_adult }
            end
          end
        RUBY
      end
    end

    context 'when the example is declared in a nested context' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          RSpec.describe Person do
            describe '#adult?' do
              context 'when the person is of age' do
                it { is_expected.to be_adult }
              end
            end
          end
        RUBY
      end
    end

    context 'when the example is declared in shared examples nested in the top-level group' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          RSpec.describe Person do
            shared_examples 'an adult' do
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
            it { is_expected.to be_adult }
          end
        RUBY
      end
    end
  end
end
